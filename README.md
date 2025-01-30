# Yooz Reader


### معرفی

**yooz reader** یک ابزار قدرتمند از زبان یوز برای پردازش ورودی‌های متنی، تجزیه قوانین و تولید پاسخ‌های تعاملی است. این ابزار برای پردازش الگوهای مکالمه، جایگزینی کلمات، مدیریت قوانین و موارد دیگر طراحی شده است.

---

### ویژگی‌ها
- پشتیبانی از دسته‌بندی‌های متنی (مانند ضمایر و افعال)
- تعریف و استفاده از قوانین برای مدیریت رفتار پاسخ‌ها
- امکان جایگزینی کلمات با استفاده از الگوها
- پشتیبانی از کلمات توقف (Stop Words)
- قابلیت مدیریت پاسخ‌های چند سطحی و شرطی
- امکان ذخیره متغیرها و استفاده از آن‌ها در پاسخ‌ها
- کاملاً قابل شخصی‌سازی و توسعه‌پذیر
- پشتیبانی از زبان‌های مختلف برای پردازش متون

---

### نحوه استفاده

#### 1. نصب و استفاده
```bash
git clone https://github.com/yooz-lang/yooz_dart.reader
cd yooz_dart.reader
dart main.dart
```


#### 2. نمونه کد
```dart
import 'yooz/yooz.dart';

void main(){
    final parser = Parser();
    
    String patternString = '''
    (
        +سلام
        -سلام
    )
    
    ''';
    
    parser.TextError = "متاسفانه متوجه نشدم";
    parser.lastMessage = 'کمک دیگه ای از دستم بر میاد؟';

    parser.loadPatterns(patternString);
    
    print(parser.parse("متن ورودی"));

}
```

#### 3. ساختار ورودی
- **الگوهای مکالمه:** `( + سوال کاربر - پاسخ های بات )`
- **تعاریف:** `#تعریف : مقدار.`
- **جایگزینی:** `{ کلمه1، کلمه2 } -> { جایگزین1، جایگزین2 }`
- **قوانین:** `{ [0.5] شرط > پاسخ }`
- **کلمات توقف:** `- { کلمه1، کلمه2 }`
- **متغیرها:** `=نام: مقدار`

---


### Introduction

**YoozParser** is a powerful tool for parsing textual inputs, managing rules, and generating interactive responses. It is designed for conversational patterns, word replacements, rule handling, and more.

---

### Features
- Support for text categories (e.g., pronouns and verbs)
- Define and apply rules to control response behavior
- Word replacement using patterns
- Stop words management
- Multi-level and conditional response handling
- Variable storage and usage in responses
- Fully customizable and extensible
- Multi-language support for text processing

---

### Usage

#### 1. Installation
```bash
dart pub add  yooz_reader
```

#### 2. Example Code
```dart
import 'yooz/yooz.dart';

void main(){
    final parser = Parser();
    
    String patternString = '''
    (
        +Hi
        -Hi
    )
    
    ''';
    
    parser.TextError = "I don't understand";
    parser.lastMessage = 'Do you have any other questions?';
    
    parser.loadPatterns(patternString);
    
    print(parser.parse("Enter Text"));

}
```

#### 3. Input Structure
- **Conversation patterns:** `( + User question - Bot responses )`
- **Definitions:** `#definition : value.`
- **Replacements:** `{ word1, word2 } -> { replacement1, replacement2 }`
- **Rules:** `{ [0.5] condition > response }`
- **Stop words:** `- { word1, word2 }`
- **Variables:** `=name: value`
