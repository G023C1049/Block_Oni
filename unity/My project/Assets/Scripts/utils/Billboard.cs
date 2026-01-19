using UnityEngine;

public class Billboard : MonoBehaviour
{
    void LateUpdate()
    {
        // カメラの方向を向く（反転しないようにforwardを合わせる）
        if (Camera.main != null)
        {
            transform.forward = Camera.main.transform.forward;
        }
    }
}