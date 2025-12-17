using System.Collections;
using System.Text;
using RenderHeads.Media.AVProVideo;
using UnityEngine;
using UnityEngine.Networking;

[System.Serializable]
public class CloudFunctionResponse
{
    public bool success;
    public string[] data;
}

public class CloudBaseFunctionCaller : MonoBehaviour
{
    [Header("CloudBase 配置")]
    public string environmentId = "你的环境ID";
    public string functionName = "YOUR_FUNCTION_NAME";
    public string accessToken = "你的 AccessToken";

    [Header("轮询设置")]
    public float pollInterval = 5f;          // 秒
    public bool autoStartPolling = true;

    private Coroutine pollingCoroutine;
    private string lastDataCache = null;     // 用于缓存上一次 data 内容
    public MediaPlayer media;

    private void Awake()
    {
        Application.runInBackground = true;  // 后台运行
    }

    private void Start()
    {
        if (autoStartPolling)
            StartPolling();
    }

    private void OnDisable()
    {
        StopPolling();
    }

    public void StartPolling()
    {
        if (pollingCoroutine != null) return;

        pollingCoroutine = StartCoroutine(PollingLoop());
        Debug.Log("[CloudBase] 轮询启动");
    }

    public void StopPolling()
    {
        if (pollingCoroutine != null)
        {
            StopCoroutine(pollingCoroutine);
            pollingCoroutine = null;
            Debug.Log("[CloudBase] 轮询停止");
        }
    }

    private IEnumerator PollingLoop()
    {
        while (true)
        {
            yield return CallFunctionOnce();
            yield return new WaitForSecondsRealtime(pollInterval); // 后台也能跑
        }
    }

    #region 云函数调用

    [System.Serializable]
    private class RequestData
    {
        public string client = "Unity";
        public long timestamp;
    }

    private IEnumerator CallFunctionOnce()
    {
        string url = $"https://{environmentId}.api.tcloudbasegateway.com/v1/functions/{functionName}";

        RequestData requestData = new RequestData
        {
            timestamp = System.DateTimeOffset.UtcNow.ToUnixTimeSeconds()
        };

        string json = JsonUtility.ToJson(requestData);

        using (UnityWebRequest request = new UnityWebRequest(url, "POST"))
        {
            request.uploadHandler = new UploadHandlerRaw(Encoding.UTF8.GetBytes(json));
            request.downloadHandler = new DownloadHandlerBuffer();
            request.SetRequestHeader("Content-Type", "application/json");
            request.SetRequestHeader("Authorization", "Bearer " + accessToken);

            yield return request.SendWebRequest();

            if (request.result == UnityWebRequest.Result.Success)
            {
                HandleResponse(request.downloadHandler.text);
            }
            else
            {
                Debug.LogError($"[CloudBase] 请求失败: {request.error} ({request.responseCode})");
                Debug.LogError(request.downloadHandler.text);
            }
        }
    }

    #endregion

    #region 数据变化检测

    private void HandleResponse(string json)
    {
        CloudFunctionResponse response;

        try
        {
            response = JsonUtility.FromJson<CloudFunctionResponse>(json);
        }
        catch
        {
            Debug.LogError("[CloudBase] JSON 解析失败: " + json);
            return;
        }

        if (response == null || response.data == null)
            return;

        // 将 data 数组序列化为字符串，用于变化检测
        string dataStr = string.Join(",", response.data);

        if (lastDataCache == null)
        {
            lastDataCache = dataStr;
            Debug.Log("[CloudBase] 初始数据已缓存: " + dataStr);
            return;
        }

        if (dataStr != lastDataCache)
        {
            lastDataCache = dataStr;
            Debug.Log("[CloudBase] 数据变化触发回调: " + dataStr);
            OnDataChanged(response.data); // 调用回调
        }
    }

    /// <summary>
    /// 当 data 内容发生变化时触发
    /// </summary>
    /// <param name="newData">最新 data 数组</param>
    private void OnDataChanged(string[] newData)
    {
        // TODO: 在这里写你的业务逻辑
        // Debug.Log("[CloudBase] 新数据: " + string.Join(",", newData));
        media.Control.Stop();
        media.OpenMedia(MediaPathType.RelativeToStreamingAssetsFolder, string.Join(",", newData),true);
        media.Control.Play();
    }

    #endregion
}
