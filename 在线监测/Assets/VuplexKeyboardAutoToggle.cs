using System.Collections;
using UnityEngine;
using Vuplex.WebView;

public class VuplexKeyboardAutoToggle : MonoBehaviour
{

    // 在 Inspector 里拖进来
    public CanvasWebViewPrefab webViewPrefab;   // 如果你用 CanvasWebViewPrefab，也可以改成 CanvasWebViewPrefab 类型
    public CanvasKeyboard keyboard;             // 如果你用 CanvasKeyboard，就把类型改成 CanvasKeyboard

    async void Start()
    {

        // 键盘初始化后先隐藏，避免启动就出现
        await keyboard.WaitUntilInitialized();
        keyboard.gameObject.SetActive(false);

        // WebView 初始化完成后，监听网页 input focus
        await webViewPrefab.WaitUntilInitialized();
        webViewPrefab.WebView.FocusedInputFieldChanged += (sender, eventArgs) => {

            // 只要网页里有文本输入框获得焦点，就显示键盘；否则隐藏
            bool shouldShow = eventArgs.Type != FocusedInputFieldType.None;
            keyboard.gameObject.SetActive(shouldShow);
        };
        StartCoroutine(wait());
    }

    IEnumerator wait() 
    {
        yield return new WaitForSeconds(30);
        keyboard.gameObject.SetActive(false);
    }
}
