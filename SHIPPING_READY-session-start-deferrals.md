VERDICT: **见文末 —— 由独立 reviewer 在 clean context 填**(builder ≠ reviewer;本卡正文只是 builder 侧机械证据)。

# pm-ledger(defer skill)SessionStart hook — 验证卡

Under review: `hooks/session-start-deferrals.sh` + `scripts/scan.sh`(经 `~/.claude/skills/do-it-later` symlink 安装,settings.json SessionStart 已注册)。
Brief 验收(EARS):`~/.claude/memory/briefs/prospective-memory-ledger.md` §验收。

## 机械证据(builder 侧,2026-08-19)

### 单元/变异自检 — `tests/run.sh` 19/19

红侧:过期日期红 · 当天到期红(边界含当天)· check 满足红 · INVALID(无条件)红 · add 拒收无条件承诺。
绿侧(不许误伤):未来日期绿 · check 不满足绿 · 全绿账 exit 0 · done/kill 后不再 DUE。
生命周期:add/fire/done/kill round-trip,kill 必带理由,重复 id 拒收。
usage log 每次 scan 落行。全程 PM_LEDGER 指向 mktemp,真账零污染。

### portability-lint(硬规矩 #4)

`scan.sh` / `session-start-deferrals.sh` / `tests/run.sh` 三件 **GATE PASS: 0 fail · 0 warn**。
(设计上规避:无 GNU date 算术——日期判定用 ISO 字典序;无 sed -i——awk>tmp&&mv。)

### 靶场(规矩:feedback_gate-trigger-surface)— `pm-ledger/range/drill.sh` 7/7

真载荷(SessionStart JSON)喂**已安装路径**的真 hook:
红账注入 `[pm-ledger]` 块 / 绿账零输出 / 主观条件账 INVALID 红。
边界三连(不 work 的形状,诚实演示):捕获漏=零信号 · 主观条件 add 拒收 · 点火面死(HOME 空巢)→ doctor `dead-surface`。
接线核:settings.json grep 到注册行。

### LIVE 枪(真 harness 调度,离线重放证明不了的那半)

```
PM_LEDGER=…/range/fixture-red.tsv claude -p "…reply TRIPPED <ids> / SILENT" --model claude-haiku-4-5-20251001
→ 模型回:TRIPPED range-past range-check     (range-future 未被误伤)
→ fixture usage log cmd=scan 行数 4 → 5      (机器证据,不依赖模型合作)
```

真账(6 条种子,均未到期)当日 scan green、doctor clean ⇒ 真 session 里 hook 静默(注入纪律:绿=零 token)。

## 已知限制(builder 自报)

- check 命令无超时护栏;纪律约束"秒级/只读/幂等"写在 SKILL.md,机器不强制。
- cron 点火面 doctor 只能标 unverifiable(bash 验不了 claude-devops 任务活性),不算绿。
- 捕获面是模型侧纪律(skill 触发词 + session 收尾扫),机器只兜 INVALID/到期,不兜"没进账"。

---

## Round 1 — 独立 reviewer verdict(2026-08-19,clean context,亲手复跑)

**NOT_READY**,1 个 blocking:**畸形行/空字段行静默蒸发**(`read_rows` 的 NF 过滤 + bash read
连续 tab 塌缩 → 已到期 pending 行对 scan/doctor/list 全隐形,零信号)。另 6 项 non-blocking:
BORROW.md 两条 ⬜ 声称入账实未入 · kill 理由带 tab 撕裂 TSV · 查重 grep 注入(id 含 `[` 可重复入账)·
check 无超时/只读强制 · 并发 done 丢更新 · 缺账本时裸奔报错。
Reviewer 亦独立复跑:tests 19/19(双 shell)· drill 7/7 · 自打 LIVE 枪命中 · 真账只读核(md5 不变)。

## Round 2 — builder 修复 + 机械证据(2026-08-19)

| Round-1 finding | 修 |
|---|---|
| blocking:畸形行蒸发 | `validate_ledger()`(awk):NF≠10 / 空字段 / 坏 status / 坏 due 格式 → **MALFORMED 红**,scan(exit 1)/doctor(FINDING)/list 三面都显;read_rows 收紧为"恰好 10 个非空字段",与 validate 配对(此处看不见 ⇒ 那里必红) |
| kill tab/换行撕裂 | `set_status` 前置守卫:tab / 换行 → rc=2 拒收 |
| 查重 grep 注入 | id 白名单 `[A-Za-z0-9._-]+` + awk 精确匹配查重(`.` 不再假阳,`[` 进不来) |
| BORROW.md 假 claim | 两条真入账:`cron-ignition-surface`(check=首现 cron: 面即火)、`clean-my-cc-lens`(due 09-16);BORROW.md 改为指名行 id |
| 缺账本裸奔 | fire/set_status 前置 ensure_ledger |
| check 超时/只读、并发锁 | **未修**,判为纪律层(SKILL.md 已声明)+ 低频;若 reviewer 判 blocking 再收 |

新增变异自检 13 条(9列行红/空字段红/坏status红/坏due红/doctor红/list显/好行不误伤/kill tab·换行拒收/怪id拒收/含点id查重不假阳/重复真被抓/done不误伤)。

Round-2 全套复跑(含 skill 改名 defer → do-it-later,全部路径引用翻新后):
**tests 32/32**(zsh 系 + `/bin/bash` 3.2 双跑)· **portability-lint 3 件 0 fail 0 warn** ·
**drill 7/7** · 真账 scan green(8 pending)/ doctor clean ·
**改名后重打 LIVE 枪**(settings.json 新路径,真 harness):`TRIPPED range-past range-check`,usage log `cmd=scan` +1。

## Round 2 — 独立 reviewer verdict(clean context,2026-08-19)

**SHIPPING_READY**。
Round 1 blocking(畸形行/空字段行静默蒸发)已灭:最小复现重打,scan/doctor/list 三面红,read_rows⟺validate_ledger 配对成立。改名 do-it-later 后零死接线(全目录 grep 0 命中 + reviewer 亲手 LIVE 枪:TRIPPED,usage log fired=1)。复跑:tests 32/32(bash 3.2 与默认 shell 双跑)· drill 7/7 · 真账 8 行 NF=10、scan 绿、doctor clean、hook 零字节、md5 不变。
留档不阻塞:check 无超时(慢 check 拖 session 开场,实测 3s)、add-vs-mutation 并发窗口可静默丢新增行(毫秒级,建议 mkdir 锁)、MALFORMED 文案对 bad-due/bad-status 行说「隐形」不准确(cosmetic,builder 已随手修)。

## Round 3 — 公开仓 push 前审(2026-08-19,同一独立 reviewer,clean re-entry)

**SHIPPING_READY(0 blocking)**。范围=公开仓 `zl190/do-it-later`(README/SKILL 公版/install/uninstall/LICENSE):
引擎三件 cmp 字节一致;install/uninstall 七场景探针全过(含畸形 JSON 无半写、他人 hook 与顶层键保留、幂等);
外部引用 4/4 到源核实;新 hook 相对路径解析经沙箱 symlink 实弹。6 个 cosmetic nit,其中 1/2/6
(HOOK_CMD 注释、失败文案、node 示例)已随 be3d510 收掉,余留档。
已 push:https://github.com/zl190/do-it-later(主 commit 5f33d7c + 文档 be3d510;线上渲染核过)。

## Round 4 — 独立 reviewer verdict(v0.3 registry 语义,2026-08-19,clean context,两轮亲手复跑)

**首审 NOT_READY**,2 个 blocking,均在 cmd_signal:
① topic 行漏进开场信号——ripe(典型 check=true)的 topic 行每 session 计入 tripped,
high 更被点名逼处置,与 cmd_match 自注释/SKILL 表/CHANGELOG 三处冲突(最小复现:单行
ripe high topic 账 → signal 红点名);② 旗舰行乱码(C3 82 C2 B7 双重编码 `·`,od 实锤)。

**复审 SHIPPING_READY(0 blocking)**,修复逐条实弹核过:
B1 灭——同一复现重打:仅 ripe high topic 行 → signal 绿 rc=0 零字节;加一条 session-start
到期行 → 只计 1、topic id 永不点名;match 面照常出列;INVALID topic 行仍计 invalid(完整性
计数保持全局)。B2 灭——全文件 LC_ALL=C 扫零非 ASCII 字节,输出改 ` | HIGH:`。
hook 注入实测一行;doctor 坏 regex 探针 topic:a(b 红、合法 regex 不误伤;私库 SKILL.md
单一 v0.3 表+新处置协议。复跑:tests 50/50(双 shell,bash 3.2)· drill 7/7 ·
portability-lint 4 件 0 fail · 引擎四件 cmp 一致 · 真账只读(md5 不变、signal 绿、doctor clean)。
**两处 claim≠code 落账并已在 push 前收掉**(builder 补,带 assert 与实弹验证):
①信号行经 "$0" 带引擎路径;②unknown-surface 文案补列 topic:<regex>;另 broken-regex
FINDING 改全英文。根因落账:python str.replace 打补丁不带 assert = 静默 no-op,
与本卡一贯的「装了等于没装」同形——**补丁必须带命中断言**。
