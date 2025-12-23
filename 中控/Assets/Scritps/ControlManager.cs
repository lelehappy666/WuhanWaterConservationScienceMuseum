using System;
using System.Collections.Generic;
using UnityEngine;

public class ControlManager : MonoBehaviour
{
    [Header("设备列表")]
    public List<LightDeviesControl> lightDevices = new List<LightDeviesControl>();
    public TcpHexClient tcpHexClient;
    private readonly KeyCode[] numberKeys =
    {
        KeyCode.Alpha0,
        KeyCode.Alpha1,
        KeyCode.Alpha2,
        KeyCode.Alpha3,
        KeyCode.Alpha4,
        KeyCode.Alpha5,
        KeyCode.Alpha6,
        KeyCode.Alpha7,
        KeyCode.Alpha8,
    };
    // Start is called once before the first execution of Update after the MonoBehaviour is created
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        for (int i = 0; i < numberKeys.Length; i++)
        {
            if (Input.GetKeyDown(numberKeys[i]))
            {
                LightControl(i + 1);
            }
        }
    }

    public void LightControl(int index)
    {
        index=index-1;
        lightDevices[index].isOpen=!lightDevices[index].isOpen;
        if(lightDevices[index].isOpen)
        {
            tcpHexClient.SendHex(lightDevices[index].openHex);
        }
        else
        {
            tcpHexClient.SendHex(lightDevices[index].closeHex);
        }
    }


}

[Serializable]
public class LightDeviesControl
{
    public string name;           // 设备名称
    public bool isOpen;            // 设备开关
    public string openHex;         // 开设备指令
    public string closeHex;         // 关设备指令
}

