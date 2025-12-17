import cloudbase from "@cloudbase/js-sdk";
import { Video } from "./types";

// Initialize TCB
// We assume the user has provided the valid VITE_TCB_ENV_ID in the .env file
const app = cloudbase.init({
  env: import.meta.env.VITE_TCB_ENV_ID || "your-env-id",
  region: "ap-shanghai", // Explicitly set region based on the provided domain
  persistence: "local" // Explicitly set persistence to local storage
});

const auth = app.auth({
  persistence: "local"
});
const db = app.database();
const collection = db.collection("WuHan");

// Singleton promise to handle concurrent auth requests
let authPromise: Promise<void> | null = null;

// Util: local storage helpers
const LS = {
  get(key: string) {
    try { return localStorage.getItem(key); } catch { return null; }
  },
  set(key: string, val: string) {
    try { localStorage.setItem(key, val); } catch { console.warn("LS.set failed"); }
  }
};

// Ensure the user is authenticated (using anonymous login)
const ensureAuth = async (force: boolean = false) => {
  // If a request is already in progress and we are not forcing a refresh, wait for it
  if (authPromise && !force) {
    return authPromise;
  }

  authPromise = (async () => {
    try {
      const loginState = await auth.getLoginState();
      console.log("Current Login State:", loginState);
      
      // If force is true, or no login state, or login state is expired (though SDK handles expiry mostly)
      if (force || !loginState) {
        console.log("Performing anonymous login...");
        await auth.signInAnonymously();
        const newState = await auth.getLoginState();
        console.log("Anonymous login successful. New State:", newState);
        console.log("Current User:", auth.currentUser);
      } else {
        // Double check if we really have a valid session by checking hasLoginState
        const hasLogin = await auth.hasLoginState();
        console.log("Has Login State check:", hasLogin);
        if (!hasLogin) {
            console.log("Login state invalid, re-logging in...");
            await auth.signInAnonymously();
            const newState = await auth.getLoginState();
            console.log("Re-login successful. New State:", newState);
        }
      }
    } catch (error) {
      console.error("Authentication failed:", error);
      authPromise = null; // Reset promise on failure so next try can run
      throw error;
    }
  })();

  return authPromise;
};

// Generic error handler and retrier for DB operations
const runWithAuthRetry = async <T>(operation: () => Promise<T>): Promise<T> => {
  try {
    await ensureAuth();
    return await operation();
  } catch (error: unknown) {
    const err = error as { message?: string; code?: string };
    console.error("Operation failed with error:", error);
    // Check for auth-related errors
    // SDK error messages can vary, covering common cases
    const isAuthError = err?.message?.includes("auth") || 
                        err?.message?.includes("authorized") || 
                        err?.code === "AUTH_INVALID" ||
                        err?.message?.includes("without auth"); // Specifically handle "without auth"

    if (isAuthError) {
      console.warn("Auth error detected, forcing re-login and retrying...", error);
      // Force re-login
      await ensureAuth(true);
      // Retry operation once
      return await operation();
    }
    throw error;
  }
};

export const fetchVideos = async (page: number = 1, limit: number = 20, search?: string): Promise<{ data: Video[], total: number }> => {
  return runWithAuthRetry(async () => {
    console.log(`Fetching videos from CloudBase... Page: ${page}, Limit: ${limit}, Search: ${search || 'None'}`);
    
    // Build the query
    let query;
    if (search) {
      // Use regex for partial matching on Name or Info
      const _ = db.command;
      // Note: TCB SDK types might have issues with method chaining for `where` after `skip`/`limit` in some versions or TypeScript definitions.
      // However, usually we should apply `where` first.
      // Let's rebuild the query order: where -> skip -> limit
      query = collection.where(_.or([
        {
          Name: {
             $regex: search,
             $options: 'i'
          }
        },
        {
          Info: {
             $regex: search,
             $options: 'i'
          }
        }
      ])).limit(limit).skip((page - 1) * limit);
    } else {
       // If no search, just standard pagination
       query = collection.limit(limit).skip((page - 1) * limit);
    }

    // Execute the query
    let res;
    try {
      res = await query.get();
    } catch (e: unknown) {
      const message = (e as Error)?.message || "";
      if (message.includes("Db or Table not exist") || message.includes("ResourceNotFound")) {
        logDebug("数据库集合 'WuHan' 不存在，请在云开发控制台创建该集合或修改代码使用已有集合名。");
        return { data: [], total: 0 };
      }
      throw e;
    }
    
    // Get total count
    let totalCount = 0;
    if (search) {
      const _ = db.command;
      try {
        const countRes = await collection.where(_.or([
          {
            Name: {
              $regex: search,
              $options: 'i'
            }
          },
          {
            Info: {
              $regex: search,
              $options: 'i'
            }
          }
        ])).count();
        totalCount = countRes.total;
      } catch (e: unknown) {
        const message = (e as Error)?.message || "";
        if (message.includes("Db or Table not exist") || message.includes("ResourceNotFound")) {
          logDebug("数据库集合 'WuHan' 不存在，统计总数失败。返回 total=0。");
          totalCount = 0;
        } else {
          throw e;
        }
      }
    } else {
      try {
        const countRes = await collection.count();
        totalCount = countRes.total;
      } catch (e: unknown) {
        const message = (e as Error)?.message || "";
        if (message.includes("Db or Table not exist") || message.includes("ResourceNotFound")) {
          logDebug("数据库集合 'WuHan' 不存在，统计总数失败。返回 total=0。");
          totalCount = 0;
        } else {
          throw e;
        }
      }
    }
    
    console.log("Fetch success, count:", res.data.length);

    return {
      data: res.data as Video[],
      total: totalCount
    };
  });
};

export const fetchVideoById = async (id: string): Promise<Video | null> => {
  return runWithAuthRetry(async () => {
    let res;
    try {
      res = await collection.doc(id).get();
    } catch (e: unknown) {
      const message = (e as Error)?.message || "";
      if (message.includes("Db or Table not exist") || message.includes("ResourceNotFound")) {
        logDebug("数据库集合 'WuHan' 不存在，无法读取影片详情。");
        return null;
      }
      throw e;
    }
    if (res.data && res.data.length > 0) {
      return res.data[0] as Video;
    }
    return null;
  });
};

// Helper to dispatch debug logs
const logDebug = (msg: string | object) => {
  const content = typeof msg === 'string' ? msg : JSON.stringify(msg, null, 2);
  console.log(`[TCB Debug] ${content}`);
  const event = new CustomEvent('tcb-debug-log', { detail: content });
  window.dispatchEvent(event);
};

// Cloud Function: connect and send play instruction
export const connectAndSendPlayInstruction = async (video: Video) => {
  return runWithAuthRetry(async () => {
    logDebug("Starting connectAndSendPlayInstruction...");
    
    // Ensure auth first
    await ensureAuth();

    // Build connection info
    let connectionId = LS.get("tcb_connection_id") || "";
    let userId = LS.get("tcb_user_id") || "";
    const device = navigator.userAgent || "web";

    // If no userId or connectionId, call connect
    if (!connectionId || !userId) {
      logDebug("No local connection info, registering...");
      connectionId = `web_${Date.now()}_${Math.random().toString(36).slice(2, 10)}`;
      // Prefer using auth uid as userId to ensure a valid string
      const authUid = auth.currentUser?.uid || `anon_${Date.now()}_${Math.random().toString(36).slice(2, 10)}`;
      userId = authUid;
      
      logDebug(`Calling 'connect' with userId=${userId}, connectionId=${connectionId}`);
      const connectPayload = {
        type: "connect",
        userId,
        connectionId,
        device
      };
      const connectMessage = JSON.stringify(connectPayload);
      let connectRes;
      try {
        connectRes = await app.callFunction({
          name: "send-instruction",
          data: {
            mode: "connect",
            connectionId,
            userId,
            device,
            message: connectMessage
          }
        });
      } catch (err: unknown) {
        const message = (err as Error)?.message || "";
        logDebug(`Connect call failed: ${message}`);
        if (message.includes("message 参数不能为空")) {
          logDebug("Detected 'message 参数不能为空' on connect, retrying with simple string...");
          const retryRes = await app.callFunction({
            name: "send-instruction",
            data: {
              mode: "connect",
              connectionId,
              userId,
              device,
              message: "connect"
            }
          });
          connectRes = retryRes;
        } else {
          throw err;
        }
      }
      
      let result = (connectRes as any)?.result || {};
      logDebug({ type: 'Connect Result', result });
      
      if (result.code === 400 && (result.message || "").includes("message 参数不能为空")) {
        logDebug("Connect returned 'message 参数不能为空', retrying with simple string...");
        const retryRes = await app.callFunction({
          name: "send-instruction",
          data: {
            mode: "connect",
            connectionId,
            userId,
            device,
            message: "connect"
          }
        });
        result = (retryRes as any)?.result || {};
        logDebug({ type: 'Connect Retry Result', result });
      }
      
      if (result.code !== 0) {
        throw new Error(result.message || "连接失败");
      }
      
      userId = result.data?.userId || userId;
      LS.set("tcb_connection_id", connectionId);
      LS.set("tcb_user_id", userId);
    } else {
        logDebug(`Using cached userId=${userId}, connectionId=${connectionId}`);
    }

    // Send play instruction
    const rawMessage = {
      type: "play",
      videoId: video._id || "",
      url: video.URL || "",
      name: video.Name || "",
      time: video.Time ?? ""
    };
    // Sanitize to plain JSON and strip undefined values
    const message = JSON.parse(JSON.stringify(rawMessage));
    if (!message || Object.keys(message).length === 0) {
      throw new Error("播放信息为空");
    }

    const messageStr = typeof message === "string" ? message : JSON.stringify(message);
    logDebug(`Sending message: ${messageStr}`);
    
    let sendRes;
    try {
      sendRes = await app.callFunction({
        name: "send-instruction",
        data: {
          mode: "send",
          userId,
          connectionId,
          message: messageStr,
          device
        }
      });
    } catch (err: unknown) {
      const message = (err as Error)?.message || "";
      logDebug(`First send attempt failed: ${message}`);
      const msg = message || "";
      if (msg.includes("message 参数不能为空")) {
        logDebug("Detected 'message 参数不能为空' from thrown error, retrying with simple string format...");
        const simpleMsg = `play:${video._id}`;
        const retryRes = await app.callFunction({
          name: "send-instruction",
          data: {
            mode: "send",
            userId,
            connectionId,
            message: simpleMsg,
            device
          }
        });
        sendRes = retryRes;
      } else {
        throw err;
      }
    }
    
    let sendResult = sendRes.result || {};
    logDebug({ type: 'Send Result', result: sendResult });

    // Check for "message 参数不能为空" error code 400
    if (sendResult.code === 400 && (sendResult.message || "").includes("message 参数不能为空")) {
         logDebug("Hit 'message empty' error, retrying with simple string format...");
         const simpleMsg = `play:${video._id}`;
         const retryRes = await app.callFunction({
          name: "send-instruction",
          data: {
            mode: "send",
            userId,
            connectionId,
            message: simpleMsg,
            device
          }
        });
        sendResult = retryRes.result || {};
        logDebug({ type: 'Retry Result', result: sendResult });
    }

    if (sendResult.code !== 0) {
      throw new Error(sendResult.message || "指令下发失败");
    }
    return sendResult;
  });
};

export const connectLoginOnly = async () => {
  return runWithAuthRetry(async () => {
    await ensureAuth();
    let connectionId = LS.get("tcb_connection_id") || "";
    let userId = LS.get("tcb_user_id") || "";
    const device = navigator.userAgent || "web";
    connectionId = connectionId || `web_${Date.now()}_${Math.random().toString(36).slice(2, 10)}`;
    userId = userId || auth.currentUser?.uid || `anon_${Date.now()}_${Math.random().toString(36).slice(2, 10)}`;
    const payload = { type: "connect", userId, connectionId, device };
    const message = JSON.stringify(payload);
    logDebug(`Login-only connect: ${message}`);
    let res;
    try {
      res = await app.callFunction({
        name: "send-instruction",
        data: { mode: "connect", connectionId, userId, device, message }
      });
    } catch (e: unknown) {
      const msg = (e as Error)?.message || "";
      logDebug(`Login-only connect failed: ${msg}`);
      if (msg.includes("message 参数不能为空")) {
        const retry = await app.callFunction({
          name: "send-instruction",
          data: { mode: "connect", connectionId, userId, device, message: "connect" }
        });
        res = retry;
      } else if (msg.includes("Db or Table not exist") || msg.includes("ResourceNotFound")) {
        logDebug("云函数依赖的数据库集合不存在，返回错误结果供前端展示");
        res = { result: { code: 500, message: "DATABASE_COLLECTION_NOT_EXIST", data: null } } as any;
      } else {
        throw e;
      }
    }
    const result = (res as any)?.result || {};
    logDebug({ type: 'Login-only Connect Result', result });
    if (result.code === 0) {
      const finalUserId = result.data?.userId || userId;
      LS.set("tcb_connection_id", connectionId);
      LS.set("tcb_user_id", finalUserId);
    }
    return result;
  });
}
