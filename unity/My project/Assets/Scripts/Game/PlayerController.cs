using UnityEngine;
using DG.Tweening;

public class PlayerController : MonoBehaviour
{
    public string PlayerId;

    // 追加: 役割ごとの初期設定
    public void Setup(string id, string role)
    {
        this.PlayerId = id;
        
        // 色を変える（Resourcesからマテリアルを読み込む簡易実装）
        // ※Assets/Resources/Mat_Oni, Mat_Runner がある前提
        string matName = (role == "Oni") ? "Mat_Oni" : "Mat_Runner";
        Material mat = Resources.Load<Material>(matName);
        
        if (mat != null)
        {
            GetComponent<Renderer>().material = mat;
        }
    }
    
    // 指定した座標へジャンプ移動する
    public void MoveToSquare(Vector3 targetPos)
    {
        Vector3 goal = targetPos + Vector3.up * 1.0f; // 高さ調整
        transform.DOJump(goal, 1.0f, 1, 0.5f).SetEase(Ease.OutQuad);
    }
}