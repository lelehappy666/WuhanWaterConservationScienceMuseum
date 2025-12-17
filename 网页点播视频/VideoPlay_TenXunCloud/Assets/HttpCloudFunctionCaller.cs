using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Networking;

// =================================================
// HTTP 调用腾讯云 CloudBase 云函数 示例脚本
//
// 说明：
// - 通过 HTTP 访问服务触发云函数
// - 云函数地址需要在 CloudBase 控制台创建 HTTP 服务
// - 云函数返回 JSON 格式:
//   { "success": true, "data": [ "path1", "path2" ] }
// =================================================

public class HttpCloudFunctionCaller : MonoBehaviour
{
    [Header("CloudBase HTTP 云函数 URL")]
    [Tooltip("替换成你在 CloudBase 控制台启用 HTTP 访问服务后生成的 URL")]
    public string cloudFunctionUrl =
        "https://YOUR_ENV_ID.service.tcloudbase.com/getAllVideoPaths";

    // Start 会在 Unity 启动时自动执行
    void Start()
    {
        StartCoroutine(CallCloudFunction());
    }

    IEnumerator CallCloudFunction()
    {
        Debug.Log("[HTTP] 开始调用云函数: " + cloudFunctionUrl);

        // 创建 GET 请求
        UnityWebRequest request = UnityWebRequest.Get(cloudFunctionUrl);

        // 可选：设置 HTTP Header
        // 如果启用了自定义 Token 验证，请取消注释
        // request.SetRequestHeader("Authorization", "Your-Token-Here");

        // 发送请求
        yield return request.SendWebRequest();

        // 网络错误处理
        if (request.result != UnityWebRequest.Result.Success)
        {
            Debug.LogError("[HTTP] 请求失败: " + request.error);
            yield break;
        }

        // 获取返回的原始 JSON 字符串
        string jsonText = request.downloadHandler.text;
        Debug.Log("[HTTP] 云函数返回 JSON:");
        Debug.Log(jsonText);

        // 解析 JSON
        VideoPathResponse response = null;
        try
        {
            response = JsonUtility.FromJson<VideoPathResponse>(jsonText);
        }
        catch (Exception e)
        {
            Debug.LogError("[HTTP] JSON 解析异常: " + e);
            yield break;
        }

        // 输出结果
        if (response != null && response.success)
        {
            Debug.Log("[HTTP] 成功获取视频路径列表, 共 " + response.data.Count + " 项");

            foreach (string p in response.data)
            {
                Debug.Log("👉 视频路径: " + p);
            }
        }
        else
        {
            Debug.LogError("[HTTP] 云函数调用失败 或 结果格式异常");
            if (response != null)
                Debug.LogError("[HTTP] 错误 message: " + response.message);
        }
    }

    // JSON 对应类
    [Serializable]
    public class VideoPathResponse
    {
        public bool success;
        public List<string> data;
        public string message;
    }
}
