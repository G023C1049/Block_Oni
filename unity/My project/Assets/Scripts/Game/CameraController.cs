using UnityEngine;
using DG.Tweening; // スムーズなズームなどに使用

public class CameraController : MonoBehaviour
{
    [Header("ターゲット")]
    public Transform target; // 回転の中心（ステージ中央）

    [Header("設定")]
    public float rotateSpeed = 5.0f; // 回転速度
    public float distance = 12.0f;   // 中心からの距離
    public float minVerticalAngle = -30f; // 縦回転の下限
    public float maxVerticalAngle = 60f;  // 縦回転の上限

    // 内部変数
    private float currentX = 0f;
    private float currentY = 20f; // 初期角度

    void Start()
    {
        // ターゲットが未設定なら、仮の中心（2.2, 2.2, 2.2）を見る
        // ※5x5マスの中心はおよそこのあたりです
        if (target == null)
        {
            GameObject tempTarget = new GameObject("CameraTarget");
            tempTarget.transform.position = new Vector3(2.2f, 2.2f, 2.2f);
            target = tempTarget.transform;
        }
    }

    void Update()
    {
        // マウスドラッグ（スマホタップ移動）で回転
        if (Input.GetMouseButton(0))
        {
            float mouseX = Input.GetAxis("Mouse X");
            float mouseY = Input.GetAxis("Mouse Y");

            currentX += mouseX * rotateSpeed;
            currentY -= mouseY * rotateSpeed;

            // 縦回転の制限
            currentY = Mathf.Clamp(currentY, minVerticalAngle, maxVerticalAngle);
        }
    }

    void LateUpdate()
    {
        if (target == null) return;

        // 計算した角度と距離でカメラ位置を決定
        Quaternion rotation = Quaternion.Euler(currentY, currentX, 0);
        Vector3 position = rotation * new Vector3(0, 0, -distance) + target.position;

        transform.rotation = rotation;
        transform.position = position;
    }
}