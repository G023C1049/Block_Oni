using UnityEngine;
using Newtonsoft.Json;
using FlutterUnityIntegration;
using BlockOni.Models;
using DG.Tweening; 
using UnityEngine.UI; 
using System.Collections;
using System.Collections.Generic;
using System.Linq; 

public class GameManager : MonoBehaviour
{
    public static GameManager Instance;

    [Header("デバッグ設定")]
    public bool isDebugMode = true;

    [Header("参照設定")]
    public GameObject playerPrefab;
    public MapGenerator mapGenerator; 
    public Text diceResultText;
    public Text gameInfoText; 
    public Camera mainCamera;
    public GameObject resultPanel; 
    public Text resultText;

    [Header("マテリアル・アイテム")]
    public Material matOni;
    public Material matRunner;
    public GameObject itemPrefab;

    [Header("ゲーム状態")]
    public List<PlayerController> players = new List<PlayerController>();
    public int currentPlayerIndex = 0;
    public int turnCount = 1;
    
    private PlayerController CurrentPlayer => players[currentPlayerIndex];
    private List<string> activeMovableIds = new List<string>(); // 現在選択可能なマス

    private bool isWaitingForDice = true;
    private bool isWaitingForDirection = false; // 方向選択待ちフラグ
    private bool isMoving = false; // 移動アニメーション中
    private bool isGameEnded = false;
    private bool isEventPlaying = false; 

    void Awake()
    {
        Instance = this;
        if (mainCamera == null) mainCamera = Camera.main;
        if (mapGenerator == null) mapGenerator = FindObjectOfType<MapGenerator>();
    }

    void Start()
    {
        if (UnityMessageManager.Instance != null) UnityMessageManager.Instance.SendMessageToFlutter("UnityReady");
        DOVirtual.DelayedCall(0.1f, InitializeGame);
    }

    void InitializeGame()
    {
        foreach(var p in players) if(p != null) Destroy(p.gameObject);
        players.Clear();

        var camController = mainCamera.GetComponent<CameraController>();
        if (camController != null && mapGenerator.MapPivot != null) camController.SetTarget(mapGenerator.MapPivot);

        SpawnPlayer("Oni1", "Oni",    "Top_0_0", matOni);
        SpawnPlayer("Oni2", "Oni",    "Top_4_0", matOni);
        SpawnPlayer("Oni3", "Oni",    "Top_0_4", matOni);
        SpawnPlayer("Runner", "Runner", "Top_2_2", matRunner);

        if (isDebugMode) SpawnRandomItems(5);
        if (resultPanel != null) resultPanel.SetActive(false);
        isGameEnded = false;
        isEventPlaying = false;

        currentPlayerIndex = 0;
        turnCount = 1;
        isWaitingForDice = true;
        isWaitingForDirection = false;
        isMoving = false;

        UpdateGameInfoUI();
        if(isDebugMode) Debug.Log($"ゲーム開始: 第{turnCount}ターン / 手番: {CurrentPlayer.PlayerId}");
    }

    void Update()
    {
        if (isGameEnded || isEventPlaying) return; 

        // ダイス (Rキー)
        if (isDebugMode && Input.GetKeyDown(KeyCode.R) && isWaitingForDice)
        {
            int baseDice = Random.Range(1, 7); 
            int finalDice = baseDice + CurrentPlayer.DiceBonus;
            
            CurrentPlayer.DiceBonus = 0;
            UpdateGameInfoUI();

            // ダイス結果を処理
            OnDiceRolled(finalDice);
            
            string json = $"{{\"type\":\"DiceRolled\", \"result\":\"{finalDice}\"}}";
            if (UnityMessageManager.Instance != null) UnityMessageManager.Instance.SendMessageToFlutter(json);
        }

        if (Input.GetMouseButtonDown(0))
        {
            HandleClickInteraction();
        }
    }

    void OnDiceRolled(int result)
    {
        ShowDiceAnimation(result);
        
        // プレイヤーに残り歩数をセット
        CurrentPlayer.RemainingSteps = result;
        
        isWaitingForDice = false;
        
        // 1歩目の処理を開始
        ProcessNextStep();
    }

    // 次の1歩をどうするか決めるメソッド
    void ProcessNextStep()
    {
        // 0. 歩数が残っていないならターン終了
        if (CurrentPlayer.RemainingSteps <= 0)
        {
            Debug.Log("移動終了");
            DOVirtual.DelayedCall(0.5f, CheckWinCondition);
            return;
        }

        // 1. 隣接する移動候補を取得
        List<string> candidates = MoveCalculator.GetImmediateCandidates(CurrentPlayer);

        // ハイライト初期化
        foreach(var sq in MapGenerator.AllSquares.Values) sq.SetHighlight(false);
        activeMovableIds.Clear();

        if (candidates.Count == 0)
        {
            // 行き止まり
            Debug.Log("行き止まり！");
            CurrentPlayer.RemainingSteps = 0;
            CheckWinCondition();
        }
        else
        {
            // ★修正: 候補が1つでも複数でも、必ずプレイヤーの入力を待つ
            // 一本道でも自動移動せず、一歩ずつ進める仕様に変更
            Debug.Log($"移動先を選択してください (残り{CurrentPlayer.RemainingSteps}歩)");
            
            isWaitingForDirection = true;
            activeMovableIds = candidates;

            // 候補をハイライト
            foreach (string id in candidates)
            {
                if(MapGenerator.AllSquares.ContainsKey(id))
                    MapGenerator.AllSquares[id].SetHighlight(true);
            }
        }
    }

    // 1歩移動を実行
    void ExecuteOneStep(string targetId)
    {
        // 入力待ち解除
        isWaitingForDirection = false;
        foreach(var sq in MapGenerator.AllSquares.Values) sq.SetHighlight(false);
        activeMovableIds.Clear();

        // プレイヤーを動かす
        CurrentPlayer.MoveOneStep(targetId, () => 
        {
            // 移動完了時のコールバック -> 次のステップへ
            UpdateGameInfoUI(); // 歩数表示更新用
            ProcessNextStep();
        });
    }

    // クリック処理
    void HandleClickInteraction()
    {
        if (isGameEnded || isEventPlaying || isMoving) return;

        // 方向選択待ちでないなら無視
        if (!isWaitingForDirection) return;

        Ray ray = mainCamera.ScreenPointToRay(Input.mousePosition);
        int layerMask = LayerMask.GetMask("Block"); 

        if (Physics.Raycast(ray, out RaycastHit hit, 100f, layerMask))
        {
            GameObject hitObj = hit.collider.gameObject;
            Square clickedSquare = hitObj.GetComponent<Square>();

            if (clickedSquare == null) return;

            // ハイライトされているマスをクリックしたら、そこへ1歩進む
            if (activeMovableIds.Contains(clickedSquare.ID))
            {
                hitObj.transform.DOPunchScale(Vector3.one * 0.2f, 0.2f, 10, 1);
                ExecuteOneStep(clickedSquare.ID);
            }
        }
    }
    
    // (以下、変更なし)
    void SpawnRandomItems(int count)
    {
        if (itemPrefab == null) return;
        var allIds = MapGenerator.AllSquares.Keys.ToList();
        int spawned = 0; int attempts = 0;
        while (spawned < count && attempts < 100) {
            attempts++;
            string randomId = allIds[Random.Range(0, allIds.Count)];
            Square sq = MapGenerator.AllSquares[randomId];
            if (sq.CurrentItem == ItemType.None) {
                sq.SpawnItem(ItemType.SpeedUp, itemPrefab);
                spawned++;
            }
        }
    }

    void SpawnPlayer(string id, string role, string startSquareId, Material mat)
    {
        if (MapGenerator.AllSquares.ContainsKey(startSquareId))
        {
            Vector3 startPos = MapGenerator.AllSquares[startSquareId].transform.position;
            GameObject pObj = Instantiate(playerPrefab, startPos + Vector3.up, Quaternion.identity);
            PlayerController pc = pObj.GetComponent<PlayerController>();
            pc.Setup(id, role, startSquareId);
            pc.SetMaterial(mat);
            players.Add(pc);
        }
    }

    void UpdateGameInfoUI() 
    {
        if (gameInfoText != null && players.Count > 0)
        {
            string role = (CurrentPlayer.Role == "Oni") ? "鬼" : "逃走者";
            string steps = (CurrentPlayer.RemainingSteps > 0) ? $" 残り{CurrentPlayer.RemainingSteps}歩" : "";
            gameInfoText.text = $"Turn {turnCount}\nPlayer: {CurrentPlayer.PlayerId} ({role}){steps}";
        }
    }

    public void OnReceiveFlutterMessage(string jsonMessage)
    {
        var data = JsonConvert.DeserializeObject<Dictionary<string, string>>(jsonMessage);
        if (data == null || !data.ContainsKey("type")) return;

        switch (data["type"])
        {
            // DiceRolledなどの受信処理は内部メソッドで完結しているため記述省略可
        }
    }

    void ShowDiceAnimation(int result)
    {
        if (diceResultText != null)
        {
            diceResultText.text = result.ToString();
            diceResultText.transform.localScale = Vector3.zero;
            diceResultText.transform.DOScale(1.5f, 0.5f).SetEase(Ease.OutBounce)
                .OnComplete(() => {
                    DOVirtual.DelayedCall(0.5f, () => { diceResultText.text = ""; });
                });
        }
    }

    void CheckWinCondition()
    {
        var runner = players.FirstOrDefault(p => p.Role == "Runner");
        var onis = players.Where(p => p.Role == "Oni").ToList();
        if (runner == null) return;
        bool oniWin = false;
        foreach (var oni in onis)
        {
            if (oni.CurrentSquareId == runner.CurrentSquareId)
            {
                oniWin = true;
                break;
            }
        }
        if (oniWin) ShowResult("ONI TEAM WIN!");
        else NextTurn();
    }

    void ShowResult(string message)
    {
        isGameEnded = true;
        if (resultPanel != null && resultText != null)
        {
            resultPanel.SetActive(true);
            resultText.text = message;
            resultText.transform.localScale = Vector3.zero;
            resultText.transform.DOScale(1.0f, 0.5f).SetEase(Ease.OutBack);
        }
        Debug.Log($"<color=red>【GAME SET】{message}</color>");
    }

    void NextTurn()
    {
        if (isGameEnded) return;
        currentPlayerIndex = (currentPlayerIndex + 1) % players.Count;
        if (currentPlayerIndex == 0) turnCount++;
        UpdateGameInfoUI();

        if (currentPlayerIndex == 0 && turnCount > 1 && (turnCount - 1) % 4 == 0)
        {
            StartCoroutine(RotateStageEvent());
        }
        else
        {
            isWaitingForDice = true;
            isWaitingForDirection = false;
            if(isDebugMode) Debug.Log($"第{turnCount}ターン / 次: {CurrentPlayer.PlayerId}");
        }
    }

    IEnumerator RotateStageEvent()
    {
        isEventPlaying = true;
        foreach(var p in players) p.transform.SetParent(mapGenerator.MapPivot);
        
        Vector3 axis = (Random.value > 0.5f) ? Vector3.right : Vector3.forward;
        mapGenerator.RotateStage(axis, 90f, 2.0f);
        
        yield return new WaitForSeconds(2.0f);
        
        foreach(var p in players) p.transform.SetParent(null);
        isEventPlaying = false;
        isWaitingForDice = true;
        isWaitingForDirection = false;
    }
}   