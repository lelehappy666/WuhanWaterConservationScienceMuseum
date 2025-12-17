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

// Local storage helpers removed with cloud function features

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

export const initAnonymousLogin = async () => {
  await ensureAuth(true);
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

// Cloud function related features have been removed
const PATH_COLLECTION = "CloudVideoPath";
const PATH_DOC_ID = "CloudVideoPath";

export const updateCloudVideoPath = async (path: string) => {
  return runWithAuthRetry(async () => {
    await ensureAuth(true);
    const col = db.collection("CloudVideoPath");
    try {
      logDebug(`准备更新路径: collection=CloudVideoPath, docId=CloudVideoPath, Path=${path}`);
      const res = await col.doc("CloudVideoPath").update({ Path: path });
      const updated = (res as any)?.updated ?? (res as any)?.data?.updated ?? 0;
      if (updated === 0) {
        logDebug("文档不存在或未更新，尝试创建/覆盖文档");
        await col.doc("CloudVideoPath").set({ Path: path });
      }
      logDebug("路径更新成功");
      const verify = await col.doc("CloudVideoPath").get();
      const after = (verify?.data?.[0] || {}) as Record<string, unknown>;
      const finalPath = (after?.Path as string) || "";
      logDebug(`写入后校验 Path=${finalPath}`);
      if (finalPath !== path) {
        return { code: 206, message: "写入未生效：请检查环境ID/地域/数据库权限配置", data: { readBack: finalPath, expected: path } };
      }
      return { code: 0, data: { Path: finalPath } };
    } catch (e: unknown) {
      const msg = (e as Error)?.message || "";
      if (msg.includes("Db or Table not exist") || msg.includes("ResourceNotFound")) {
        return { code: 404, message: "集合不存在: CloudVideoPath" };
      }
      if (msg.includes("without auth") || msg.includes("AUTH_INVALID")) {
        return { code: 401, message: "未授权：请配置 Web 安全域名并开启匿名登录" };
      }
      if (msg.toLowerCase().includes("permission") || msg.includes("PermissionDenied")) {
        return { code: 403, message: "权限不足：请在数据库权限规则中允许写入该文档" };
      }
      throw e;
    }
  });
};
