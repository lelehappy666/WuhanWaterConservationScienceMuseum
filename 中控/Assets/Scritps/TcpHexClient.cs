using System;
using System.Net.Sockets;
using System.Text;
using UnityEngine;

public class TcpHexClient : MonoBehaviour
{
    [Header("TCP设置")]
    public string serverIP = "127.0.0.1"; // 服务器IP
    public int serverPort = 12345;        // 服务器端口

    private TcpClient client;
    private NetworkStream stream;

    void Start()
    {
        ConnectToServer();
    }

    void OnApplicationQuit()
    {
        Disconnect();
    }

    /// <summary>
    /// 连接服务器
    /// </summary>
    public void ConnectToServer()
    {
        try
        {
            client = new TcpClient();
            client.Connect(serverIP, serverPort);
            stream = client.GetStream();
            Debug.Log("TCP 已连接到服务器: " + serverIP + ":" + serverPort);
        }
        catch (Exception ex)
        {
            Debug.LogError("TCP连接失败: " + ex.Message);
        }
    }

    /// <summary>
    /// 发送HEX字符串到服务器
    /// </summary>
    /// <param name="hexString">例如 "01 02 0A FF"</param>
    public void SendHex(string hexString)
    {
        if (stream == null || !client.Connected)
        {
            Debug.LogError("未连接服务器");
            return;
        }

        try
        {
            byte[] data = HexStringToBytes(hexString);
            stream.Write(data, 0, data.Length);
            Debug.Log("发送HEX数据: " + hexString);
        }
        catch (Exception ex)
        {
            Debug.LogError("发送失败: " + ex.Message);
        }
    }

    /// <summary>
    /// 断开连接
    /// </summary>
    public void Disconnect()
    {
        if (stream != null) stream.Close();
        if (client != null) client.Close();
        Debug.Log("TCP 已断开连接");
    }

    /// <summary>
    /// HEX字符串转换为字节数组
    /// </summary>
    private byte[] HexStringToBytes(string hex)
    {
        hex = hex.Replace(" ", ""); // 去掉空格
        if (hex.Length % 2 != 0)
            throw new Exception("无效的HEX字符串长度");

        byte[] bytes = new byte[hex.Length / 2];
        for (int i = 0; i < bytes.Length; i++)
        {
            bytes[i] = Convert.ToByte(hex.Substring(i * 2, 2), 16);
        }
        return bytes;
    }
}
