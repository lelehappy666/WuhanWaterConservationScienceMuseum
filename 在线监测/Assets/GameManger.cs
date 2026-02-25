using RenderHeads.Media.AVProVideo;
using System;
using System.Diagnostics;
using System.IO;
using UnityEngine;

public class GameManger : MonoBehaviour
{
    public MediaPlayer meidia;
    public DisplayUGUI displayUGUI;
    public GameObject homePage;
    public GameObject homeBack;
    // Start is called before the first frame update
    void Start()
    {
        QualitySettings.vSyncCount = 1;      // 通常锁到 60（跟显示器刷新率）
        Application.targetFrameRate = -1;    // 用VSync就别再手动限帧
        Application.runInBackground = false;
        Screen.fullScreenMode = FullScreenMode.FullScreenWindow;
        Screen.fullScreen = true;


    }

    // Update is called once per frame
    void Update()
    {

    }
    public void OpenVideo()
    {
        displayUGUI.gameObject.SetActive(true);
        meidia.OpenVideoFromFile(MediaPlayer.FileLocation.RelativeToStreamingAssetsFolder,"media.mp4",true);
        meidia.Play();
        homePage.SetActive(false);
    }

    public void CloseVideo()
    {
        displayUGUI.gameObject.SetActive(false);
        meidia.Stop();
        homePage.SetActive(true);
    }
    public void OpenWeb()
    {
        homePage.SetActive(false);
        homeBack.SetActive(true);
    }
    public void CloseWeb()
    {
        homePage.SetActive(true);
        homeBack.SetActive(false);
        GetComponent<VuplexKeyboardAutoToggle>().keyboard.gameObject.SetActive(false);
    }
}
