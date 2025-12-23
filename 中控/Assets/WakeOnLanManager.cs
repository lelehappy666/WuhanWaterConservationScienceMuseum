using System;
using System.Collections.Generic;
using System.Net;
using System.Net.Sockets;
using UnityEngine;

[Serializable]
public class WolDevice
{
    public string name;           // 设备名称
    public string mac;            // WOL 用
    public string ip;             // 设备 IP（可用于命令和 WOL）

    [Header("端口设置")]
    public int wolPort = 9;       // 魔术包端口（开机）
    public int commandPort = 5000; // UDP 关机 / 命令端口

    public bool enabled = true;

    [Header("关机命令（每台可不同）")]
    public string shutdownCommand;
}




public class WakeOnLanManager : MonoBehaviour
{
    [Header("设备列表（每台独立 IP）")]
    public List<WolDevice> devices = new List<WolDevice>();

    [Header("调试")]
    public bool wakeAllOnStart = false;

    private void Start()
    {
        if (wakeAllOnStart)
        {
            WakeAll();
        }
    }

    // =========================
    // 对外接口
    // =========================

    /// <summary>
    /// 唤醒所有启用的设备（逐台发送）
    /// </summary>
    public void WakeAll()
    {
        foreach (var d in devices)
        {
            if (!d.enabled) continue;
            SendMagicPacket(d);
        }
    }

    /// <summary>
    /// 按名称唤醒
    /// </summary>
    public void Wake(string deviceName)
    {
        var d = devices.Find(x => x.name == deviceName && x.enabled);
        if (d == null)
        {
            Debug.LogWarning($"[WOL] 未找到设备: {deviceName}");
            return;
        }

        SendMagicPacket(d);
    }

    /// <summary>
    /// UI 用（按索引）
    /// </summary>
    public void WakeByIndex(int index)
    {
        if (index < 0 || index >= devices.Count)
        {
            Debug.LogWarning("[WOL] 索引越界");
            return;
        }

        var d = devices[index];
        if (!d.enabled)
        {
            Debug.LogWarning($"[WOL] 设备未启用: {d.name}");
            return;
        }

        SendMagicPacket(d);
    }

    // =========================
    // 核心逻辑
    // =========================

   private void SendMagicPacket(WolDevice d)
{
    byte[] macBytes = ParseMac(d.mac);
    byte[] packet = BuildPacket(macBytes);

    using (UdpClient client = new UdpClient())
    {
        client.EnableBroadcast = true;
        IPEndPoint ep = new IPEndPoint(IPAddress.Parse(d.ip), d.wolPort);
        client.Send(packet, packet.Length, ep);
    }

    Debug.Log($"[WOL] 已发送 → {d.name} | {d.ip}:{d.wolPort}");
}


    private byte[] BuildPacket(byte[] mac)
    {
        byte[] packet = new byte[6 + 16 * mac.Length];

        for (int i = 0; i < 6; i++)
            packet[i] = 0xFF;

        for (int i = 6; i < packet.Length; i += mac.Length)
            Buffer.BlockCopy(mac, 0, packet, i, mac.Length);

        return packet;
    }

    private byte[] ParseMac(string mac)
    {
        string clean = mac.Replace(":", "").Replace("-", "");

        if (clean.Length != 12)
            throw new ArgumentException("MAC 地址格式错误");

        byte[] bytes = new byte[6];
        for (int i = 0; i < 6; i++)
            bytes[i] = Convert.ToByte(clean.Substring(i * 2, 2), 16);

        return bytes;
    }
}
