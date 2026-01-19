using UnityEngine;

public class CameraController : MonoBehaviour
{
    [Header("ターゲット")]
    public Transform target; // MapPivot

    [Header("設定")]
    public float distance = 15.0f;   // 全体が見えるように少し引く
    public float rotateSpeed = 5.0f; 
    public float minVerticalAngle = -10f; 
    public float maxVerticalAngle = 80f;  

    [Header("位置調整")]
    // ★ここが重要: 中心をY方向にずらす設定
    public Vector3 focusOffset = new Vector3(0, 2.5f, 0); 

    private float currentX = 0f;
    private float currentY = 30f; 

    void Start()
    {
        Vector3 angles = transform.eulerAngles;
        currentX = angles.y;
        currentY = angles.x;
    }

    public void SetTarget(Transform newTarget)
    {
        target = newTarget;
    }

    void Update()
    {
        if (Input.GetMouseButton(0))
        {
            currentX += Input.GetAxis("Mouse X") * rotateSpeed;
            currentY -= Input.GetAxis("Mouse Y") * rotateSpeed;
            currentY = Mathf.Clamp(currentY, minVerticalAngle, maxVerticalAngle);
        }
    }

    void LateUpdate()
    {
        Vector3 targetPos = (target != null) ? target.position : Vector3.zero;

        // ★ターゲット位置にずらし量を足す
        Vector3 finalTargetPos = targetPos + focusOffset;

        Quaternion rotation = Quaternion.Euler(currentY, currentX, 0);
        Vector3 negDistance = new Vector3(0.0f, 0.0f, -distance);
        
        Vector3 position = rotation * negDistance + finalTargetPos;

        transform.rotation = rotation;
        transform.position = position;
    }

    // ★デバッグ機能: カメラが見ている場所を赤い玉で表示
    void OnDrawGizmos()
    {
        if (target != null)
        {
            Gizmos.color = Color.red;
            // 現在の注視点を描画
            Gizmos.DrawSphere(target.position + focusOffset, 0.5f);
        }
    }
}