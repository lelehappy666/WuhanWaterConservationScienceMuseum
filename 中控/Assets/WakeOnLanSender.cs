using System;
using System.Net;
using System.Net.Sockets;
using UnityEngine;

public class WakeOnLanSender : MonoBehaviour
{
    [Header("Wake-on-LAN 设置")]
    [Tooltip("目标设备 MAC 地址，例如：AA:BB:CC:DD:EE:FF")]
    public string macAddress = "AA:BB:CC:DD:EE:FF";

    [Tooltip("广播地址，通常为 255.255.255.255")]
    public string broadcastIP = "255.255.255.255";

    [Tooltip("UDP 端口，常用 7 或 9")]
    public int port = 9;

    [Header("调试")]
    public bool sendOnStart = false;

    private void Start()
    {
        if (sendOnStart)
        {
            SendMagicPacket();
        }
    }

    /// <summary>
    /// 发送 Wake-on-LAN 魔术包
    /// </summary>
    public void SendMagicPacket()
    {
        try
        {
            byte[] macBytes = ParseMacAddress(macAddress);
            byte[] magicPacket = BuildMagicPacket(macBytes);

            using (UdpClient client = new UdpClient())
            {
                client.EnableBroadcast = true;
                IPEndPoint endPoint = new IPEndPoint(
                    IPAddress.Parse(broadcastIP),
                    port
                );

                client.Send(magicPacket, magicPacket.Length, endPoint);
            }

            Debug.Log($"[WOL] 魔术包已发送 → MAC: {macAddress}");
        }
        catch (Exception ex)
        {
            Debug.LogError($"[WOL] 发送失败: {ex.Message}");
        }
    }

    /// <summary>
    /// 构建魔术包（6字节FF + 16次MAC）
    /// </summary>
    private byte[] BuildMagicPacket(byte[] mac)
    {
        byte[] packet = new byte[6 + 16 * mac.Length];

        // 前 6 字节全是 0xFF
        for (int i = 0; i < 6; i++)
        {
            packet[i] = 0xFF;
        }

        // 后面重复 16 次 MAC 地址
        for (int i = 6; i < packet.Length; i += mac.Length)
        {
            Buffer.BlockCopy(mac, 0, packet, i, mac.Length);
        }

        return packet;
    }

    /// <summary>
    /// 解析 MAC 地址字符串
    /// </summary>
    private byte[] ParseMacAddress(string mac)
    {
        string cleanMac = mac.Replace(":", "").Replace("-", "");

        if (cleanMac.Length != 12)
            throw new ArgumentException("MAC 地址格式错误");

        byte[] macBytes = new byte[6];
        for (int i = 0; i < 6; i++)
        {
            macBytes[i] = Convert.ToByte(cleanMac.Substring(i * 2, 2), 16);
        }

        return macBytes;
    }
}
