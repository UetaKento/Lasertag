# CLAUDE.md

このファイルはClaude Codeがこのリポジトリで作業する際のガイダンスです。

---

## プロジェクト概要

**Lasertag** は Meta Quest 3 専用の Mixed Reality（MR）レーザータグゲームです。
同じ物理空間にいる複数のプレイヤーが現実の空間をアリーナとして対戦する、実験的なマルチプレイヤーゲームです。

- Meta Horizon Store でベータ配信中
- 個人開発・実験フェーズ
- 公式サイト: https://anagly.ph/

---

## 技術スタック

| 分類 | 内容 |
|------|------|
| **エンジン** | Unity 6.0.0 LTS (`6000.0.58f1`) |
| **ターゲット** | Meta Quest 3（Android / OpenXR） |
| **グラフィックス** | Universal Render Pipeline (URP) 17.2.0 |
| **シェーダー** | ShaderGraph 17.2.0, VFX Graph 17.2.0 |
| **XR SDK** | Meta XR SDK v83 (com.meta.xr.sdk.core) |
| **ネットワーク** | Netcode for GameObjects 2.7.0 + Unity Transport 2.6.0 |
| **マルチプレイ** | Unity Multiplayer Services 1.1.8 |
| **XR入力** | XR Interaction Toolkit 3.2.2, New Input System 1.14.2 |
| **コントローラ** | Striker VR SDK 0.9.0 |
| **空間同期** | Meta Shared Anchor / AprilTag（両方対応、WIP） |

---

## プロジェクト構造

```
Assets/
├── Anaglyph/
│   ├── LaserTag/          ★ メインゲームコード（主な作業場所）
│   │   ├── MainScene/     - メインゲームシーン
│   │   ├── Player/        - ローカルプレイヤー・アバター
│   │   ├── Weapons/       - 武器・弾丸
│   │   ├── Matches/       - マッチ管理・ゲームロジック
│   │   ├── Objects/       - ゲームオブジェクト（Base, Flag, ControlPoint）
│   │   ├── Interface/     - UI（HUD, メニュー）
│   │   ├── Boundary/      - プレイエリア境界
│   │   ├── Tools/         - ゲーム内ツール（Spawner等）
│   │   ├── ControllerSupport/ - StrikerVR対応
│   │   ├── Operator/      - オペレーター用機能（Freecam等）
│   │   └── Settings/      - ゲーム設定
│   ├── XRTemplate/        - XR共通フレームワーク（SharedSpaces, Anchors等）
│   ├── Netcode/           - Netcodeユーティリティ（NetworkObjectPool等）
│   ├── AudioPooling/      - オーディオプーリング
│   ├── InGameConsole/     - デバッグコンソール
│   ├── Input/             - 入力管理
│   ├── Menu/              - UIメニュー基盤
│   └── DriftCorrectionWIP/ ⚠️ 変更・履歴修正禁止（WIPフォルダ）
├── MetaXR/                - Meta XR SDK アセット
├── Oculus/                - Oculus SDKアセット
└── Plugins/               - Androidプラグイン
```

**メインシーン:** `Assets/Anaglyph/LaserTag/MainScene/MainScene.unity`

---

## 重要なシステムとクラス

### プレイヤーアーキテクチャ

| クラス | 役割 |
|--------|------|
| `MainPlayer` (MonoBehaviour) | ローカルプレイヤーの状態管理（体力、生死、入力）。ネットワーク非依存 |
| `PlayerAvatar` (NetworkBehaviour) | ネットワーク上のプレイヤー表現。全クライアントで同期 |
| `TeamOwner` | チーム所属の同期 |

- `MainPlayer.Instance` → ローカルプレイヤーへのアクセス
- `PlayerAvatar.Local` → 自分のネットワークアバターへのアクセス
- `PlayerAvatar.All` → 全プレイヤーの辞書 `Dictionary<ulong, PlayerAvatar>`

### マッチシステム

```csharp
// MatchState の遷移
NotPlaying → Mustering → Countdown → Playing → NotPlaying

// 主なアクセスポイント
MatchReferee.Instance      // シングルトン
MatchReferee.State         // 現在の状態
MatchReferee.Settings      // マッチ設定（MatchSettings struct）
MatchReferee.StateChanged  // 状態変化イベント
```

### コロケーション（空間同期）

- **現状:** WIP・実験的。主な作業テーマ
- 2つの方式をサポート: `MetaSharedAnchor` / `AprilTag`
- ホストが方式を選択し `NetworkVariable` で同期
- 主要クラス: `ColocationManager`（XR Rig.prefab に依存）

### ネットワーク管理

- `NetcodeManagement.State` / `NetcodeManagement.StateChanged` でネットワーク状態を監視
- `NetworkObjectPool` で弾丸などのオブジェクトプーリング

---

## コードスタイルと規則

### フォーマット
- **インデント:** タブ（`.editorconfig` で定義）
- **名前空間:** 自由（既存コードは `Anaglyph.Lasertag.*` を使用）

### 設計方針
- **小さいクラスへの分割を優先**する（1クラス1責任）
- コメントは最小限。自己説明的なコードを書く
- テストコードは不要（Unity実機テストで確認）

### よく使うパターン

**シングルトン:**
```csharp
public static MyClass Instance { get; private set; }
private void Awake() { Instance = this; }
```

**イベント（常に初期化）:**
```csharp
public static event Action EventName = delegate { };
public static event Action<T> EventWithArg = delegate { };
```

**Netcode RPC（Unity Netcode v2 スタイル）:**
```csharp
[Rpc(SendTo.Everyone)]
public void MyRpc() { ... }

[Rpc(SendTo.Owner)]
public void OwnerOnlyRpc() { ... }

[Rpc(SendTo.Everyone, InvokePermission = RpcInvokePermission.Owner)]
private void OwnerInvokedRpc() { ... }
```

**Unity 6 の非同期処理:**
```csharp
await Awaitable.NextFrameAsync(cancellationToken);
await Awaitable.WaitForSecondsAsync(seconds, cancellationToken);
```

**ネットワーク変数:**
```csharp
private readonly NetworkVariable<T> mySync = new(defaultValue);
// OnValueChanged で変化を検知
mySync.OnValueChanged += (oldVal, newVal) => { ... };
```

---

## 重要な注意事項

### 変更してはいけない場所
- **`Assets/Anaglyph/DriftCorrectionWIP/`** は変更・git履歴修正禁止のWIPフォルダ
- **`Assets/Anaglyph/`配下の汎用ライブラリ**（LaserTag固有でない部分）は原則触らない

### 開発・テスト環境
- Unity Editor（Play Mode）と Quest 3 実機の両方でテスト
- Editor上では XR が無効になるため `XRSettings.enabled` のチェックが随所にある

### Claudeへの期待
- 指示は**日本語**で行う。回答も**日本語で詳しく**説明する
- コード変更後に自動でコミット・プッシュ等は行わない（常に確認を取る）
- 頼んでいない箇所のリファクタリングや変更は行わない
- 現在の主要テーマ: **コロケーション（空間同期）の改善**

---

## Assembly Definition

主要な `.asmdef`:
- `Lasertag.asmdef` → LaserTagゲームコード全体
- `Anaglyph.XRTemplate.*` → XRフレームワーク
- `Anaglyph.Netcode.*` → Netcodeユーティリティ
