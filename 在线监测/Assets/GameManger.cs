using System.Collections;
using System.Collections.Generic;
using RenderHeads.Media.AVProVideo;
using UnityEngine;
using Vuplex.WebView;
using  Vuplex.Demos ;

public class GameManger : MonoBehaviour
{
    public MediaPlayer meidia;
    public DisplayUGUI displayUGUI;
    public LoadWebURL canvasPopup;
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        
    }
    public void OpenVideo()
    {
        displayUGUI.gameObject.SetActive(true);
        meidia.OpenMedia(MediaPathType.RelativeToStreamingAssetsFolder,"media.mp4",true);
        meidia.Play();
        canvasPopup.isOpenWebURL=false;
        canvasPopup.mainWebViewClonePrefab.SetActive(false);
    }

    public void CloseVideo()
    {
        displayUGUI.gameObject.SetActive(false);
        meidia.Stop();
        canvasPopup.mainWebViewClonePrefab.SetActive(true);
    }
    public void OpenWeb()
    {
        canvasPopup.isOpenWebURL=true;
    }
}
