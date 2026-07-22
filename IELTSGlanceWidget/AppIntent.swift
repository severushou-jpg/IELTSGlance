//
//  AppIntent.swift
//  IELTSGlanceWidget
//
//  Created by severushou on 2026/7/16.
//

import AppIntents

enum WidgetVocabularyPack: String, AppEnum, CaseIterable {
    case pack01 = "ielts-pack-01"
    case pack02 = "ielts-pack-02"
    case pack03 = "ielts-pack-03"
    case pack04 = "ielts-pack-04"
    case pack05 = "ielts-pack-05"
    case pack06 = "ielts-pack-06"
    case pack07 = "ielts-pack-07"
    case pack08 = "ielts-pack-08"
    case pack09 = "ielts-pack-09"
    case pack10 = "ielts-pack-10"
    case pack11 = "ielts-pack-11"
    case pack12 = "ielts-pack-12"
    case pack13 = "ielts-pack-13"
    case pack14 = "ielts-pack-14"
    case pack15 = "ielts-pack-15"

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "IELTS study topic"
    static let caseDisplayRepresentations: [WidgetVocabularyPack: DisplayRepresentation] = [
        .pack01: "写作论证与证据 · 观点、评价与逻辑",
        .pack02: "图表趋势与比较 · Task 1 数据语言",
        .pack03: "因果变化与解决方案 · 原因、影响与对策",
        .pack04: "描述评价与程度 · 性质、质量与强弱",
        .pack05: "沟通语言与媒体 · 表达、信息与新闻",
        .pack06: "教育研究与学习 · 学校、能力与成长",
        .pack07: "工作商业与经济 · 职业、金融与贸易",
        .pack08: "社会政府与公共服务 · 政策、群体与福利",
        .pack09: "环境自然与能源 · 生态、气候与资源",
        .pack10: "科学技术与工程 · 发现、设备与创新",
        .pack11: "健康身心与医疗 · 疾病、治疗与福祉",
        .pack12: "人物性格与关系 · 情绪、家庭与行为",
        .pack13: "法律犯罪与冲突 · 司法、安全与权利",
        .pack14: "城市住房与交通 · 城市化与基础设施",
        .pack15: "生活文化与消费 · 饮食、艺术与休闲"
    ]
}
