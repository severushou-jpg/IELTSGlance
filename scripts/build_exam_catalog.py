#!/usr/bin/env python3
"""Build the multi-exam vocabulary catalog used by the app and widget."""

from __future__ import annotations

import json
import re
import csv
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
IELTS_PACKS = ROOT / "Shared" / "Resources" / "ielts_word_packs.json"
OUTPUT = ROOT / "Shared" / "Resources" / "exam_vocabulary_catalog.json"
CET4_SOURCE = Path("/tmp/cet4.json")
CET6_SOURCE = Path("/tmp/cet6.json")
GRE_SOURCE = Path("/tmp/ecdict.csv")

WORD_PATTERN = re.compile(r"^[a-z][a-z-]*$")

GRE_THEMES = [
    ("personality", "性格与人格特质", "人物性格、品质和行为倾向", "person.crop.circle.fill", "temperament character personality trait vanity humble timid bold sincere arrogant proud prudent wary impulsive patient stubborn capricious", "性格 人格 谦卑 傲慢 胆怯 勇敢 真诚 固执 谨慎 冲动 虚荣"),
    ("emotion", "情绪与心理状态", "情绪波动、心理反应和感受", "brain.head.profile", "emotion mood anxiety fear anger grief joy melancholy serene frantic calm restless perplexed confused", "情绪 心理 焦虑 恐惧 愤怒 悲伤 喜悦 忧郁 平静 困惑"),
    ("attitude", "态度、立场与评价", "态度判断、褒贬评价和偏向", "hand.thumbsup.fill", "attitude stance opinion view judgment evaluate praise condemn contempt disdain esteem skepticism bias neutral hostile favorable", "态度 立场 评价 赞扬 谴责 蔑视 尊重 怀疑 偏见 中立 敌意"),
    ("argument", "争论、批判与反驳", "争议表达、批评和反论证", "bubble.left.and.exclamationmark.bubble.right.fill", "argue dispute debate criticize refute rebut contradict controversy objection polemic attack censure denounce", "争论 辩论 批判 反驳 反对 矛盾 争议 谴责"),
    ("support", "赞同、支持与证明", "证据、确认、支持和背书", "checkmark.seal.fill", "support prove evidence confirm justify validate corroborate advocate endorse uphold substantiate verify demonstrate", "支持 证明 证据 确认 认可 维护 证实 论证"),
    ("deception", "欺骗、伪装与虚假", "虚假、隐瞒、伪装和误导", "theatermasks.fill", "deceive fraud fake false disguise conceal pretend hypocrisy illusion spurious counterfeit feign lie", "欺骗 伪装 虚假 隐藏 假装 伪善 幻觉 伪造"),
    ("clarity", "清晰、模糊与复杂", "清楚、含混、复杂和晦涩", "eye.fill", "clear obscure vague ambiguous lucid explicit subtle intricate complex tangled opaque confused simplify explain", "清晰 模糊 暧昧 明确 复杂 微妙 晦涩 简化 解释"),
    ("change", "变化、发展与衰退", "变化趋势、增长和恶化", "arrow.triangle.2.circlepath", "change alter transform develop evolve decline decay deteriorate improve progress growth diminish fluctuate vary", "变化 改变 转变 发展 演化 衰退 恶化 改善 增长 减少 波动"),
    ("power", "权力、统治与服从", "权威、控制、支配和服从", "crown.fill", "power authority rule command dominate obey submit control govern tyrant sovereign compel coerce", "权力 权威 统治 命令 支配 服从 控制 政府 强迫"),
    ("society", "社会制度与群体", "群体关系、制度和公共生活", "person.3.fill", "society institution community public civic collective group class hierarchy custom convention policy", "社会 制度 群体 公共 集体 阶层 等级 习俗 政策"),
    ("morality", "道德、正义与责任", "伦理判断、责任和公正", "scalemass.fill", "moral justice virtue duty responsibility guilt innocent ethical righteous corrupt blame merit conscience", "道德 正义 责任 罪责 无辜 伦理 正直 腐败 良心"),
    ("art", "艺术、审美与风格", "艺术风格、审美和品味", "paintpalette.fill", "art aesthetic beauty style elegant ornate plain taste craft visual sculpture music dramatic graceful", "艺术 审美 美 丑 风格 优雅 华丽 朴素 品味 工艺"),
    ("language", "文学、语言与表达", "文学、修辞和表达方式", "text.quote", "literature language verbal rhetoric expression narrative prose poetry metaphor eloquent concise verbose articulate", "文学 语言 表达 修辞 叙事 诗 隐喻 雄辩 简洁 冗长"),
    ("science", "科学研究与方法", "研究方法、观察和实证", "atom", "science research experiment theory hypothesis empirical observe analyze method data evidence objective", "科学 研究 实验 理论 假设 经验 观察 分析 方法 数据"),
    ("logic", "逻辑、推理与因果", "逻辑关系、推断和因果", "point.topleft.down.curvedto.point.bottomright.up", "logic reason infer imply cause consequence premise conclusion paradox consistent valid fallacy rational", "逻辑 推理 因果 前提 结论 悖论 一致 有效 谬误 理性"),
    ("quantity", "数量、程度与范围", "数量大小、程度和比例", "number", "quantity amount degree extent range abundant scarce excessive moderate immense minute partial total proportion", "数量 程度 范围 大量 稀少 过度 适度 巨大 微小 部分 全部 比例"),
    ("time", "时间、持续与短暂", "时间状态、速度和延续", "clock.fill", "time duration temporary permanent ancient modern delay swift gradual sudden transient perpetual periodic", "时间 持续 短暂 永久 古代 现代 延迟 迅速 逐渐 突然 周期"),
    ("space", "空间、位置与移动", "空间位置、移动和方向", "location.fill", "space place position move motion travel route distant near expand contract scatter gather", "空间 位置 移动 运动 旅行 路径 遥远 附近 扩张 收缩"),
    ("rarity", "稀有、平凡与典型", "稀有性、普通性和典型性", "sparkles", "rare common typical ordinary exceptional peculiar unique universal conventional usual strange normal", "稀有 普通 典型 平凡 异常 独特 普遍 传统 奇怪 正常"),
    ("importance", "重要、琐碎与无关", "重要程度、相关性和价值", "exclamationmark.circle.fill", "important trivial relevant irrelevant essential significant minor central peripheral crucial negligible matter", "重要 琐碎 相关 无关 必要 显著 次要 核心 边缘 关键"),
    ("difficulty", "困难、障碍与解决", "问题、阻碍和解决动作", "wrench.and.screwdriver.fill", "difficulty obstacle problem challenge solve overcome hinder impede facilitate ease arduous troublesome", "困难 障碍 问题 挑战 解决 克服 阻碍 促进 艰难 麻烦"),
    ("conflict", "冲突、战争与破坏", "冲突、攻击、威胁和损害", "bolt.shield.fill", "conflict war fight attack destroy damage ruin violent hostile aggression weapon threat", "冲突 战争 攻击 破坏 损害 毁灭 暴力 敌对 威胁"),
    ("order", "和解、秩序与稳定", "秩序、平衡、稳定和恢复", "shield.lefthalf.filled", "peace order stable reconcile harmony calm settle regulate maintain restore balance discipline", "和平 秩序 稳定 和解 和谐 平静 调节 维持 恢复 平衡"),
    ("resource", "财富、贫困与资源", "经济资源、贫富和成本", "banknote.fill", "wealth poor poverty resource money economic cost profit debt scarce abundant luxury", "财富 贫困 资源 金钱 经济 成本 利润 债务 稀缺 丰富 奢侈"),
    ("work", "工作、效率与能力", "工作能力、效率和执行", "briefcase.fill", "work labor skill ability efficient competent diligent idle industry task perform achieve", "工作 劳动 技能 能力 效率 胜任 勤奋 懒惰 任务 完成"),
    ("education", "教育、知识与学习", "学习、教学、知识和理解", "graduationcap.fill", "education knowledge learn teach study scholar academic ignorance wisdom understand instruct train", "教育 知识 学习 教授 学者 学术 无知 智慧 理解 训练"),
    ("nature", "自然、环境与生物", "自然环境、物种和生态", "leaf.fill", "nature environment plant climate earth water forest organic species ecological", "自然 环境 植物 气候 地球 水 森林 物种 生态"),
    ("tradition", "宗教、传统与仪式", "信仰、传统、仪式和习俗", "building.columns.fill", "religion tradition ritual sacred holy belief myth worship custom ceremony orthodox", "宗教 传统 仪式 神圣 信仰 神话 崇拜 习俗 正统"),
    ("health", "身体、疾病与医学", "身体健康、疾病和治疗", "cross.case.fill", "body health disease medical illness pain cure heal physical fatigue injury symptom", "身体 健康 疾病 医学 疼痛 治疗 痊愈 疲劳 受伤 症状"),
    ("abstract", "综合抽象高频词", "概念、性质、状态和趋势", "square.grid.3x3.fill", "abstract general concept idea notion quality state condition principle phenomenon tendency", "抽象 概念 观念 性质 状态 条件 原则 现象 倾向"),
]


def slug(value: str) -> str:
    cleaned = re.sub(r"[^a-z0-9]+", "-", value.lower()).strip("-")
    return cleaned or "word"


def positive_rank(value: str) -> int:
    try:
        rank = int(value or 0)
        return rank if rank > 0 else 1_000_000
    except ValueError:
        return 1_000_000


def clean_chinese(value: str) -> str:
    value = value.replace("\\n", "\n")
    lines = [line.strip() for line in value.splitlines() if line.strip() and not line.startswith("[")]
    pieces: list[str] = []
    for line in lines:
        line = re.sub(r"^(vt|vi|v|n|a|ad|adv|prep|conj|int|pron|num)\.\s*", "", line, flags=re.I)
        line = re.sub(r"\[[^]]*\]", "", line)
        line = re.sub(r"\([^)]*\)", "", line)
        for piece in re.split(r"[,，;；]", line):
            cleaned = piece.strip(" ；;，,")
            if cleaned and cleaned not in pieces:
                pieces.append(cleaned)
            if len(pieces) == 2:
                return "；".join(pieces)[:28].rstrip("；")
    return ("；".join(pieces) or "释义待补充")[:28].rstrip("；")


def part_of_speech(row: dict) -> str:
    translation = (row.get("translation") or "").strip().lower()
    definition = (row.get("definition") or "").strip().lower()
    marker = ""
    for value in (translation, definition):
        match = re.match(r"(vt|vi|v|n|a|adj|ad|adv|prep|conj|int|pron|num)\.", value)
        if match:
            marker = match.group(1)
            break
    if not marker:
        pos = (row.get("pos") or "").strip().lower()
        marker = pos.split(":", 1)[0].split("/", 1)[0]
    return {
        "vt": "v.",
        "vi": "v.",
        "v": "v.",
        "n": "n.",
        "a": "adj.",
        "adj": "adj.",
        "ad": "adv.",
        "adv": "adv.",
        "prep": "prep.",
        "conj": "conj.",
        "int": "int.",
        "pron": "pron.",
        "num": "num.",
    }.get(marker, "n.")


def definition_fragments(value: str, word: str) -> list[str]:
    fragments: list[str] = []
    for line in value.replace("\\n", "\n").splitlines():
        line = re.sub(r"^(vt|vi|v|n|a|adj|ad|adv|prep|conj|int|pron|num)\.\s*", "", line.strip(), flags=re.I)
        for piece in re.split(r"[,;]", line):
            cleaned = piece.strip(" .")
            if not cleaned or word.lower() in cleaned.lower() or len(cleaned) > 28:
                continue
            if cleaned not in fragments:
                fragments.append(cleaned)
            if len(fragments) == 3:
                return fragments
    return fragments


def gre_word(row: dict, index: int, theme_name: str) -> dict:
    word = row["word"].strip().lower()
    synonyms = definition_fragments(row.get("definition") or "", word)
    while len(synonyms) < 1:
        synonyms.append("GRE theme word")
    return {
        "id": f"gre-{index:04d}-{slug(word)}",
        "word": word,
        "partOfSpeech": part_of_speech(row),
        "chineseMeaning": clean_chinese(row.get("translation") or ""),
        "synonyms": synonyms[:3],
        "exampleSentence": f'Review "{word}" in the {theme_name} theme.',
        "source": "ECDICT gre-tagged headword; IELTS Glance normalized",
    }


def gre_theme_score(row: dict, keyword_blob: str, chinese_blob: str) -> int:
    text = " ".join(
        [
            row.get("word") or "",
            row.get("definition") or "",
            row.get("translation") or "",
        ]
    ).lower()
    score = 0
    for keyword in keyword_blob.split():
        if re.search(rf"\b{re.escape(keyword)}\b", text):
            score += 3
    for keyword in chinese_blob.split():
        if keyword in text:
            score += 2
    return score


def gre_packs(source: Path) -> list[dict]:
    rows = []
    seen = set()
    with source.open(encoding="utf-8", newline="") as handle:
        for row in csv.DictReader(handle):
            word = (row.get("word") or "").strip().lower()
            tags = set((row.get("tag") or "").lower().split())
            if "gre" not in tags or not WORD_PATTERN.fullmatch(word):
                continue
            if tags.intersection({"zk", "gk", "cet4", "cet6"}):
                continue
            if word in seen or not clean_chinese(row.get("translation") or ""):
                continue
            seen.add(word)
            rows.append(row)

    rows.sort(key=lambda row: (positive_rank(row.get("bnc", "")), positive_rank(row.get("frq", "")), row.get("word", "")))
    if len(rows) < 3000:
        raise RuntimeError(f"Expected at least 3000 GRE words, got {len(rows)}")

    scored: list[dict] = []
    for row in rows:
        theme_scores = [
            gre_theme_score(row, keywords, chinese_keywords)
            for _, _, _, _, keywords, chinese_keywords in GRE_THEMES
        ]
        best_score = max(theme_scores)
        best_theme = theme_scores.index(best_score) if best_score > 0 else len(GRE_THEMES) - 1
        scored.append(
            {
                "row": row,
                "bestTheme": best_theme,
                "scores": theme_scores,
                "rank": min(positive_rank(row.get("bnc", "")), positive_rank(row.get("frq", ""))),
            }
        )

    selected_by_theme: list[list[dict]] = [[] for _ in GRE_THEMES]
    used_words: set[str] = set()
    for theme_index in range(len(GRE_THEMES)):
        candidates = [
            item for item in scored
            if item["bestTheme"] == theme_index and item["row"]["word"] not in used_words
        ]
        candidates.sort(key=lambda item: (-item["scores"][theme_index], item["rank"], item["row"]["word"]))
        for item in candidates[:100]:
            selected_by_theme[theme_index].append(item)
            used_words.add(item["row"]["word"])

    for theme_index in range(len(GRE_THEMES)):
        if len(selected_by_theme[theme_index]) >= 100:
            continue
        candidates = [
            item for item in scored
            if item["row"]["word"] not in used_words
        ]
        candidates.sort(key=lambda item: (-item["scores"][theme_index], item["rank"], item["row"]["word"]))
        for item in candidates[: 100 - len(selected_by_theme[theme_index])]:
            selected_by_theme[theme_index].append(item)
            used_words.add(item["row"]["word"])

    packs = []
    word_index = 1
    for order, ((theme_id, name, subtitle, icon, _, _), items) in enumerate(zip(GRE_THEMES, selected_by_theme), start=1):
        if len(items) != 100:
            raise RuntimeError(f"Expected 100 GRE words for {name}, got {len(items)}")
        words = []
        for item in sorted(items, key=lambda value: (value["rank"], value["row"]["word"])):
            words.append(gre_word(item["row"], word_index, name))
            word_index += 1
        packs.append(
            {
                "id": f"gre-{theme_id}-pack-{order:02d}",
                "name": name,
                "subtitle": subtitle,
                "systemImage": icon,
                "order": order,
                "words": words,
            }
        )
    return packs


def cet_word(item: dict, index: int, exam_id: str, exam_label: str) -> dict:
    translations = item.get("translations") or []
    first_translation = translations[0] if translations else {}
    part_of_speech = (first_translation.get("type") or "n.").strip()
    if part_of_speech and not part_of_speech.endswith("."):
        part_of_speech += "."

    meanings = []
    for translation in translations:
        text = (translation.get("translation") or "").strip()
        if text:
            meanings.append(text)
    chinese_meaning = "；".join(meanings[:2]) or "释义待补充"

    phrases = item.get("phrases") or []
    synonyms = []
    for phrase in phrases:
        text = (phrase.get("phrase") or "").strip()
        if text and text.lower() != item["word"].lower():
            synonyms.append(text)
        if len(synonyms) == 3:
            break
    while len(synonyms) < 1:
        synonyms.append(f"{exam_label} core word")

    word = item["word"].strip()
    example = f"Review {word} quickly during a {exam_label} vocabulary sprint."
    return {
        "id": f"{exam_id}-{index:04d}-{slug(word)}",
        "word": word,
        "partOfSpeech": part_of_speech,
        "chineseMeaning": chinese_meaning,
        "synonyms": synonyms,
        "exampleSentence": example,
        "source": f"KyleBing/english-vocabulary {exam_label} JSON; first 1500 entries; IELTS Glance normalized",
    }


def cet_packs(source: Path, exam_id: str, exam_name: str, exam_label: str) -> list[dict]:
    source_words = json.loads(source.read_text(encoding="utf-8"))
    selected = []
    seen = set()
    for item in source_words:
        word = (item.get("word") or "").strip()
        key = word.lower()
        if not word or key in seen:
            continue
        seen.add(key)
        selected.append(cet_word(item, len(selected) + 1, exam_id, exam_label))
        if len(selected) == 1500:
            break

    if len(selected) != 1500:
        raise RuntimeError(f"Expected 1500 {exam_label} words, got {len(selected)}")

    bands = [
        ("high", "高频", "优先扫熟", "flame.fill"),
        ("mid", "中频", "巩固拓展", "chart.bar.fill"),
        ("low", "低频", "查漏补缺", "tray.2.fill"),
    ]
    packs = []
    for band_index, (band_id, band_name, band_subtitle, icon) in enumerate(bands):
        for offset in range(5):
            order = band_index * 5 + offset + 1
            start = (order - 1) * 100
            end = start + 100
            range_label = f"{start + 1}-{end}"
            packs.append(
                {
                    "id": f"{exam_id}-{band_id}-pack-{offset + 1:02d}",
                    "name": f"{exam_name}{band_name} {offset + 1:02d}",
                    "subtitle": f"第 {range_label} 词，{band_subtitle}",
                    "systemImage": icon,
                    "order": order,
                    "words": selected[start:end],
                }
            )
    return packs


def main() -> None:
    if not CET4_SOURCE.exists():
        raise FileNotFoundError(f"Missing CET4 source file: {CET4_SOURCE}")
    if not CET6_SOURCE.exists():
        raise FileNotFoundError(f"Missing CET6 source file: {CET6_SOURCE}")
    if not GRE_SOURCE.exists():
        raise FileNotFoundError(f"Missing GRE source file: {GRE_SOURCE}")

    ielts_packs = json.loads(IELTS_PACKS.read_text(encoding="utf-8"))
    catalog = {
        "schemaVersion": 1,
        "exams": [
            {
                "id": "ielts",
                "name": "雅思",
                "subtitle": "雅思考试核心词汇",
                "systemImage": "graduationcap.fill",
                "order": 1,
                "packs": ielts_packs,
            },
            {
                "id": "cet4",
                "name": "四级",
                "subtitle": "大学英语四级 1500 高频词",
                "systemImage": "4.circle.fill",
                "order": 2,
                "packs": cet_packs(CET4_SOURCE, "cet4", "四级", "CET4"),
            },
            {
                "id": "cet6",
                "name": "六级",
                "subtitle": "大学英语六级 1500 高频词",
                "systemImage": "6.circle.fill",
                "order": 3,
                "packs": cet_packs(CET6_SOURCE, "cet6", "六级", "CET6"),
            },
            {
                "id": "gre",
                "name": "GRE",
                "subtitle": "GRE 3000 主题词",
                "systemImage": "sparkle.magnifyingglass",
                "order": 4,
                "packs": gre_packs(GRE_SOURCE),
            },
        ],
    }
    OUTPUT.write_text(
        json.dumps(catalog, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


if __name__ == "__main__":
    main()
