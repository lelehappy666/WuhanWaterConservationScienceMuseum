import React, { useEffect, useState } from 'react';
import cloudbase from '@cloudbase/js-sdk';

export const DebugPanel: React.FC = () => {
  const [logs, setLogs] = useState<string[]>([]);
  const [status, setStatus] = useState<string>('Checking...');
  const [user, setUser] = useState<any>(null);

  const addLog = (msg: string) => {
    setLogs(prev => [...prev, `${new Date().toLocaleTimeString()} - ${msg}`]);
  };

  const checkConnection = async () => {
    try {
      addLog("Initializing CloudBase check...");
      // Re-init to be sure (or just use existing if global, but here we test isolation)
      // We read env vars directly
      const envId = import.meta.env.VITE_TCB_ENV_ID;
      addLog(`Env ID: ${envId}`);
      
      const app = cloudbase.init({
        env: envId,
        region: "ap-shanghai",
        persistence: "local"
      });

      const auth = app.auth({ persistence: "local" });
      
      addLog("Checking login state...");
      const loginState = await auth.getLoginState();
      addLog(`Login State: ${loginState ? 'Logged In' : 'Not Logged In'}`);

      if (!loginState) {
        addLog("Attempting Anonymous Login...");
        await auth.signInAnonymously();
        addLog("Anonymous Login Success!");
      }
      
      setUser(auth.currentUser);
      
      addLog("Testing Database Connection (WuHan collection)...");
      const db = app.database();
      const count = await db.collection("WuHan").count();
      addLog(`Database Connected! Total records: ${count.total}`);
      setStatus("Success");

    } catch (error: any) {
      console.error(error);
      addLog(`ERROR: ${error.message}`);
      setStatus("Error");
      if (error.message.includes("without auth")) {
        addLog("CRITICAL: 'without auth' error means 'Web Safe Domain' is missing localhost:5173");
      }
      if (error.message.includes("Db or Table not exist") || error.message.includes("ResourceNotFound")) {
        addLog("CRITICAL: 数据库集合 'WuHan' 不存在或未创建");
        addLog("请在云开发控制台 -> 数据库中新建集合 'WuHan'，并导入数据");
        addLog("如您使用其他集合名，请修改代码中的 collection('WuHan') 为实际集合名");
      }
    }
  };

  useEffect(() => {
    checkConnection();
    
    // Listen for custom debug events
    const handleDebugLog = (e: CustomEvent) => {
      if (e.detail) {
        addLog(e.detail);
      }
    };
    window.addEventListener('tcb-debug-log' as any, handleDebugLog);
    return () => window.removeEventListener('tcb-debug-log' as any, handleDebugLog);
  }, []);

  return (
    <div className="fixed bottom-4 right-4 w-96 bg-black/90 text-green-400 p-4 rounded-lg shadow-xl z-50 font-mono text-xs overflow-hidden border border-green-500/30">
      <div className="flex justify-between items-center mb-2 border-b border-green-500/30 pb-2">
        <h3 className="font-bold">System Diagnostics</h3>
        <span className={`px-2 py-0.5 rounded ${status === 'Success' ? 'bg-green-900 text-green-200' : 'bg-red-900 text-red-200'}`}>
          {status}
        </span>
      </div>
      <div className="h-48 overflow-y-auto space-y-1">
        {logs.map((log, i) => (
          <div key={i}>{log}</div>
        ))}
      </div>
      <div className="mt-2 pt-2 border-t border-green-500/30 flex justify-between">
        <button 
            onClick={() => { setLogs([]); checkConnection(); }}
            className="px-3 py-1 bg-green-800 hover:bg-green-700 text-white rounded transition-colors"
        >
          Retry Connection
        </button>
        {user && <span className="text-gray-400">UID: {user.uid.slice(0, 8)}...</span>}
      </div>
    </div>
  );
};
