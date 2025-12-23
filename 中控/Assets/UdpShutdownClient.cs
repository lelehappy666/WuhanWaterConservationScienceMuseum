using System;
using System.Net;
using System.Net.Sockets;
using System.Text;
using UnityEngine;

public class UdpShutdownClient : MonoBehaviour
{
    [Header("设备数据来源")]
    public WakeOnLanManager wolManager;

    [Header("调试")]
    public bool shutdownAllOnStart = false;

    private void Start()
    {
        if (shutdownAllOnStart)
        {
            ShutdownAll();
        }
    }

    // =========================
    // 对外接口
    // =========================

    /// <summary>
    /// 关机所有启用设备（使用各自命令）
    /// </summary>
    public void ShutdownAll()
    {
        foreach (var d in wolManager.devices)
        {
            if (!d.enabled) continue;
            SendShutdown(d);
        }
    }

    /// <summary>
    /// 按名称关机
    /// </summary>
    public void Shutdown(string deviceName)
    {
        var d = wolManager.devices.Find(x => x.name == deviceName && x.enabled);
        if (d == null)
        {
            Debug.LogWarning($"[UDP-SHUTDOWN] 未找到设备: {deviceName}");
            return;
        }

        SendShutdown(d);
    }

    /// <summary>
    /// UI 用（按索引）
    /// </summary>
    public void ShutdownByIndex(int index)
    {
        if (index < 0 || index >= wolManager.devices.Count)
        {
            Debug.LogWarning("[UDP-SHUTDOWN] 索引越界");
            return;
        }

        var d = wolManager.devices[index];
        if (!d.enabled)
        {
            Debug.LogWarning($"[UDP-SHUTDOWN] 设备未启用: {d.name}");
            return;
        }

        SendShutdown(d);
    }

    // =========================
    // 核心实现
    // =========================

   
   private void SendShutdown(WolDevice d)
    {
        if (string.IsNullOrEmpty(d.shutdownCommand))
        {
            Debug.LogWarning($"[UDP] {d.name} 未配置关机命令");
            return;
        }

        byte[] data = Encoding.UTF8.GetBytes(d.shutdownCommand);

        using (UdpClient client = new UdpClient())
        {
            IPEndPoint ep = new IPEndPoint(IPAddress.Parse(d.ip), d.commandPort);
            client.Send(data, data.Length, ep);
        }

        Debug.Log($"[UDP] 已发送 → {d.name} | {d.ip}:{d.commandPort}");
    }


}
