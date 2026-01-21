using UnityEngine;
using UnityEngine.Scripting;
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
    public int MaxTurnLimit = 10;
    
    private PlayerController CurrentPlayer => players[currentPlayerIndex];
    private List<string> activeMovableIds = new List<string>(); 

    private bool isWaitingForDice = true;
    private bool isWaitingForDirection = false; 
    private bool isMoving = false; 
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
        string readyJson = $"{{\"type\":\"UnityReady\"}}";
        if (UnityMessageManager.Instance != null) UnityMessageManager.Instance.SendMessageToFlutter(readyJson);
        
        DOVirtual.DelayedCall(0.1f, InitializeGame);
    }

    void InitializeGame()
    {
        foreach(var p in players) if(p != null) Destroy(p.gameObject);
        players.Clear();

        var camController = mainCamera.GetComponent<CameraController>();
        if (camController != null && mapGenerator.MapPivot != null) camController.SetTarget(mapGenerator.MapPivot);

        SpawnPlayer("Runner", "Runner", "Top_2_2", matRunner);
        SpawnPlayer("Oni1", "Oni",    "Top_0_0", matOni);
        SpawnPlayer("Oni2", "Oni",    "Top_4_0", matOni);
        SpawnPlayer("Oni3", "Oni",    "Top_0_4", matOni);

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
        SendTurnChangeToFlutter(); 
        
        if(isDebugMode) Debug.Log($"ゲーム開始: 第{turnCount}ターン / 手番: {CurrentPlayer.PlayerId}");
    }

    void Update()
    {
        if (isGameEnded || isEventPlaying) return; 

        if (isDebugMode && Input.GetKeyDown(KeyCode.R))
        {
            if (CurrentPlayer.RemainingSteps <= 0) ReceiveDiceResult(Random.Range(1, 7));
        }

        if (Input.GetMouseButtonDown(0)) HandleClickInteraction();
    }

    void ReceiveDiceResult(int baseResult)
    {
        Debug.Log($"ReceiveDiceResult called: base={baseResult}");
        try
        {
            int bonus = CurrentPlayer.DiceBonus;
            int finalResult = baseResult + bonus;

            string json = $"{{\"type\":\"DiceCalculated\", \"base\":\"{baseResult}\", \"bonus\":\"{bonus}\", \"total\":\"{finalResult}\"}}";
            if (UnityMessageManager.Instance != null) UnityMessageManager.Instance.SendMessageToFlutter(json);

            CurrentPlayer.DiceBonus = 0;
            UpdateGameInfoUI();
            OnDiceRolled(finalResult);
        }
        catch (System.Exception e)
        {
            Debug.LogError($"ReceiveDiceResult Error: {e.Message}");
        }
    }

    void OnDiceRolled(int result)
    {
        ShowDiceAnimation(result);
        CurrentPlayer.RemainingSteps = result;
        CurrentPlayer.TotalStepsInTurn = result; 
        isWaitingForDice = false; 
        ProcessNextStep();
    }

    void ProcessNextStep()
    {
        if (CurrentPlayer.RemainingSteps <= 0)
        {
            Debug.Log("移動終了");
            DOVirtual.DelayedCall(0.5f, CheckWinCondition);
            return;
        }

        List<string> candidates = MoveCalculator.GetImmediateCandidates(CurrentPlayer);
        foreach(var sq in MapGenerator.AllSquares.Values) sq.SetHighlight(false);
        activeMovableIds.Clear();

        if (candidates.Count == 0)
        {
            Debug.Log("行き止まり！");
            CurrentPlayer.RemainingSteps = 0;
            CheckWinCondition();
        }
        else if (candidates.Count == 1)
        {
            isWaitingForDirection = true;
            activeMovableIds = candidates;
            MapGenerator.AllSquares[candidates[0]].SetHighlight(true);
        }
        else
        {
            Debug.Log($"移動先を選択してください (残り{CurrentPlayer.RemainingSteps}歩)");
            isWaitingForDirection = true;
            activeMovableIds = candidates;
            foreach (string id in candidates)
            {
                if(MapGenerator.AllSquares.ContainsKey(id))
                    MapGenerator.AllSquares[id].SetHighlight(true);
            }
        }
    }

    void ExecuteOneStep(string targetId)
    {
        isWaitingForDirection = false;
        foreach(var sq in MapGenerator.AllSquares.Values) sq.SetHighlight(false);
        activeMovableIds.Clear();

        CurrentPlayer.MoveOneStep(targetId, () => 
        {
            UpdateGameInfoUI();
            ProcessNextStep();
        });
    }

    void HandleClickInteraction()
    {
        if (isGameEnded || isEventPlaying || isMoving) return;
        if (!isWaitingForDirection) return;

        Ray ray = mainCamera.ScreenPointToRay(Input.mousePosition);
        int layerMask = LayerMask.GetMask("Block"); 

        if (Physics.Raycast(ray, out RaycastHit hit, 100f, layerMask))
        {
            GameObject hitObj = hit.collider.gameObject;
            Square clickedSquare = hitObj.GetComponent<Square>();
            if (clickedSquare == null) return;

            if (activeMovableIds.Contains(clickedSquare.ID))
            {
                hitObj.transform.DOPunchScale(Vector3.one * 0.2f, 0.2f, 10, 1);
                ExecuteOneStep(clickedSquare.ID);
            }
        }
    }
    
    public void ActivateItem(string itemType)
    {
        if (isGameEnded || isEventPlaying) return;
        Debug.Log($"アイテム使用: {itemType}");

        switch(itemType)
        {
            case "Teleport":
                var validCandidates = MapGenerator.AllSquares.Values
                    .Where(sq => Vector3.Dot(sq.transform.up, Vector3.down) < 0.5f) 
                    .Select(sq => sq.ID)
                    .ToList();

                if (validCandidates.Count > 0)
                {
                    string randomId = validCandidates[Random.Range(0, validCandidates.Count)];
                    CurrentPlayer.ForceMoveTo(randomId, () => {
                        CheckWinCondition();
                    });
                }
                else
                {
                    Debug.LogWarning("ワープ可能なマスが見つかりませんでした");
                }
                break;

            case "StageRotate":
                StartCoroutine(RotateStageEvent(1.0f));
                break;
            
            // ★修正: AddDiceValueを削除し、SpeedUpのみにする
            case "SpeedUp":
                if (!isWaitingForDice)
                {
                    Debug.LogWarning("ダイスを振った後なので加速アイテムは使えません");
                    return; 
                }
                CurrentPlayer.DiceBonus += 2;
                UpdateGameInfoUI();
                break;
        }
    }

    void SpawnRandomItems(int count)
    {
        if (itemPrefab == null) return;

        var availableSquares = MapGenerator.AllSquares.Values
            .Where(sq => sq.CurrentItem == ItemType.None)
            .ToList();

        if (count > availableSquares.Count) count = availableSquares.Count;

        // ★修正: アイテム種別を3種類に限定
        List<ItemType> allTypes = new List<ItemType> { 
            ItemType.SpeedUp, 
            ItemType.Teleport, 
            ItemType.StageRotate 
        };

        int spawnedCount = 0;

        while (spawnedCount < count && availableSquares.Count > 0)
        {
            ItemType nextType;

            if (spawnedCount < allTypes.Count)
            {
                // フェーズA: 最初の3回で全種類を配置
                nextType = allTypes[spawnedCount];
            }
            else
            {
                // フェーズB: 残りはランダム
                nextType = allTypes[Random.Range(0, allTypes.Count)];
            }

            int targetIndex = Random.Range(0, availableSquares.Count);
            Square targetSq = availableSquares[targetIndex];

            targetSq.SpawnItem(nextType, itemPrefab);

            availableSquares.RemoveAt(targetIndex);
            
            spawnedCount++;
        }
        
        Debug.Log($"アイテム生成完了: {spawnedCount}個 (3種類配置保証済み)");
    }

    void SpawnPlayer(string id, string role, string startSquareId, Material mat)
    {
        if (MapGenerator.AllSquares.ContainsKey(startSquareId))
        {
            Square sq = MapGenerator.AllSquares[startSquareId];
            Vector3 startPos = sq.transform.position;
            Vector3 normal = sq.UpVector;
            float heightOffset = 0.6f;
            GameObject pObj = Instantiate(playerPrefab, startPos + normal * heightOffset, Quaternion.identity);
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
            gameInfoText.text = $"Turn {turnCount}/{MaxTurnLimit}\nPlayer: {CurrentPlayer.PlayerId} ({role}){steps}";

            string statusMsg = $"Turn {turnCount} / 手番: {CurrentPlayer.PlayerId}";
            if (CurrentPlayer.RemainingSteps > 0) statusMsg += $" (残り{CurrentPlayer.RemainingSteps}歩)";
            
            string json = $"{{\"type\":\"StatusUpdate\", \"message\":\"{statusMsg}\"}}";
            if (UnityMessageManager.Instance != null) UnityMessageManager.Instance.SendMessageToFlutter(json);
        }
    }

    void SendTurnChangeToFlutter()
    {
        string json = $"{{\"type\":\"TurnChange\", \"playerId\":\"{CurrentPlayer.PlayerId}\"}}";
        if (UnityMessageManager.Instance != null) UnityMessageManager.Instance.SendMessageToFlutter(json);
    }

    [Preserve] 
    public void OnReceiveFlutterMessage(string jsonMessage)
    {
        Debug.Log($"<color=cyan>【Flutter受信】: {jsonMessage}</color>");
        try
        {
            var data = JsonConvert.DeserializeObject<Dictionary<string, string>>(jsonMessage);
            if (data == null || !data.ContainsKey("type")) return;

            switch (data["type"])
            {
                case "DiceRolled":
                    if (isEventPlaying || CurrentPlayer.RemainingSteps > 0) 
                    {
                        Debug.LogWarning($"ダイス命令を無視: Event={isEventPlaying}, Steps={CurrentPlayer.RemainingSteps}");
                        return;
                    }
                    if (!isWaitingForDice && CurrentPlayer.RemainingSteps > 0)
                    {
                        Debug.LogWarning("ダイス不可状態");
                        return;
                    }

                    if(data.ContainsKey("result")) ReceiveDiceResult(int.Parse(data["result"]));
                    break;

                case "UseItem":
                    if(data.ContainsKey("itemId")) ActivateItem(data["itemId"]);
                    break;
            }
        }
        catch(System.Exception e)
        {
            Debug.LogError($"メッセージ受信エラー: {e.Message}");
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
        
        if (oniWin) 
        {
            ShowResult("ONI TEAM WIN!");
            return;
        }

        if (turnCount >= MaxTurnLimit && currentPlayerIndex == players.Count - 1)
        {
            ShowResult("RUNNER WINS! (Time Up)");
            return;
        }

        NextTurn();
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
        string json = $"{{\"type\":\"GameEnd\", \"result\":\"{message}\"}}";
        if (UnityMessageManager.Instance != null) UnityMessageManager.Instance.SendMessageToFlutter(json);
        Debug.Log($"<color=red>【GAME SET】{message}</color>");
    }

    void NextTurn()
    {
        if (isGameEnded) return;
        
        currentPlayerIndex = (currentPlayerIndex + 1) % players.Count;
        if (currentPlayerIndex == 0) turnCount++;
        
        CurrentPlayer.RemainingSteps = 0;
        isWaitingForDice = true; 
        isWaitingForDirection = false;
        
        UpdateGameInfoUI();
        SendTurnChangeToFlutter();

        if (currentPlayerIndex == 0 && turnCount > 1 && (turnCount - 1) % 4 == 0)
        {
            isWaitingForDice = false; 
            StartCoroutine(RotateStageEvent());
        }
        else
        {
            if(isDebugMode) Debug.Log($"第{turnCount}ターン / 次: {CurrentPlayer.PlayerId}");
        }
    }

    IEnumerator RotateStageEvent(float duration = 2.0f)
    {
        isEventPlaying = true;
        foreach(var p in players) p.transform.SetParent(mapGenerator.MapPivot);
        
        Vector3 axis = (Random.value > 0.5f) ? Vector3.right : Vector3.forward;
        mapGenerator.RotateStage(axis, 90f, duration);
        yield return new WaitForSeconds(duration);
        
        foreach(var p in players) p.transform.SetParent(null);

        CheckAndTeleportBottomPlayers();

        isEventPlaying = false;
        isWaitingForDice = true; 
        isWaitingForDirection = false;
        
        SendTurnChangeToFlutter();
    }

    void CheckAndTeleportBottomPlayers()
    {
        foreach(var p in players)
        {
            if(!MapGenerator.AllSquares.ContainsKey(p.CurrentSquareId)) continue;
            
            Square currentSq = MapGenerator.AllSquares[p.CurrentSquareId];
            
            if (Vector3.Dot(currentSq.transform.up, Vector3.down) > 0.9f)
            {
                Debug.Log($"{p.PlayerId} is on BOTTOM face! Teleporting...");
                Square targetSq = FindTopSquareAt(currentSq.transform.position.x, currentSq.transform.position.z);
                
                if (targetSq != null)
                {
                    p.CurrentSquareId = targetSq.ID;
                    Vector3 targetPos = targetSq.transform.position;
                    Vector3 normal = targetSq.UpVector;
                    float heightOffset = 0.6f;
                    p.transform.position = targetPos + normal * heightOffset;
                    
                    Vector3 forward = p.transform.forward;
                    if (Mathf.Abs(Vector3.Dot(forward, normal)) > 0.99f) forward = Vector3.forward;
                    p.transform.rotation = Quaternion.LookRotation(forward, normal);
                }
            }
        }
    }

    Square FindTopSquareAt(float worldX, float worldZ)
    {
        Square bestSq = null;
        float maxY = -999f;
        
        foreach(var sq in MapGenerator.AllSquares.Values)
        {
            if (Mathf.Abs(sq.transform.position.x - worldX) < 0.2f &&
                Mathf.Abs(sq.transform.position.z - worldZ) < 0.2f)
            {
                if (sq.transform.position.y > maxY)
                {
                    maxY = sq.transform.position.y;
                    bestSq = sq;
                }
            }
        }
        return bestSq;
    }
}