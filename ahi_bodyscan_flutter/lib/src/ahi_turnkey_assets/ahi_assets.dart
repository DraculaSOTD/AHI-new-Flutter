//
//  AHI Assets - Asset path constants for Turnkey integration
//
//  Copyright (c) AHI. All rights reserved.
//

class AHIAssets {
  // Base path
  static const String _basePath = 'assets/ahi_turnkey';
  
  // Images
  static const String _imagesPath = '$_basePath/images';
  
  // Guide Images
  static const String clothingGuide = '$_imagesPath/clothing-guide.png';
  static const String phoneGuide = '$_imagesPath/phone-guide.png';
  static const String phoneGuideWide = '$_imagesPath/phone-guide-wide.png';
  static const String lightGuide = '$_imagesPath/light-guide.jpeg';
  
  // Scan Guide Images
  static const String facescanGuide = '$_imagesPath/facescan-guide.png';
  static const String facescanGuideBg = '$_imagesPath/facescan-guide-bg.png';
  static const String facescanGuideFace = '$_imagesPath/facescan-guide-face.png';
  static const String facescanStars = '$_imagesPath/facescan-stars.png';
  static const String fingerscanGuide = '$_imagesPath/fingerscan-guide.png';
  
  // BHA Welcome Images
  static const String bhaAnxietyWelcome = '$_imagesPath/bha-anxiety-welcome.png';
  static const String bhaDepressionWelcome = '$_imagesPath/bha-depression-welcome.png';
  static const String bhaProfileWelcome = '$_imagesPath/bha-profile-welcome.png';
  static const String wellnessWelcome = '$_imagesPath/wellness-welcome.png';
  
  // Icons & SVGs
  static const String logo = '$_imagesPath/logo.svg';
  static const String reportLogo = '$_imagesPath/report-logo.svg';
  static const String calendarIcon = '$_imagesPath/calendar_icon.svg';
  static const String circleFilled = '$_imagesPath/circle-filled.svg';
  static const String bodyCompoIcon = '$_imagesPath/bodyCompoIcon.svg';
  static const String crpIcon = '$_imagesPath/crp_icon.svg';
  static const String depAnxIcon = '$_imagesPath/depAnxIncon.svg';
  static const String dmrIcon = '$_imagesPath/dmrIcon.svg';
  static const String inflammationIcon = '$_imagesPath/inflamationIcon.svg';
  static const String lipidsIcon = '$_imagesPath/lipidsIcon.svg';
  static const String metabolicIcon = '$_imagesPath/metabolicIcon.svg';
  static const String wave = '$_imagesPath/wave.gif';
  
  // Audio Assets
  static const String _audioPath = '$_basePath/audios';
  static const String beep1x = '$_audioPath/beep1x.m4a';
  static const String beep3x = '$_audioPath/beep3x.m4a';
  
  // Font Families
  static const String fontAHIIcon = 'AHIIcon';
  static const String fontSFPro = 'SFPro';
  static const String fontOpenSans = 'OpenSans';
  static const String fontAlaska = 'Alaska';
  static const String fontArial = 'Arial';
  
  // 3D Models
  static const String _cubePath = '$_basePath/cube';
  static const String bodyMesh = '$_cubePath/7da01f58-a56a-4626-a9fa-6dc5cd5ca9a2.obj';
  
  // JSON Configuration Files
  static const String _jsonPath = '$_basePath/json';
  
  // Classification JSON Files
  static const String _classificationsPath = '$_jsonPath/classifications';
  static const String tenYearCvd = '$_classificationsPath/10_year_cvd.json';
  static const String activityLevel = '$_classificationsPath/activity_level.json';
  static const String anxiety = '$_classificationsPath/anxiety.json';
  static const String arterialStiffness = '$_classificationsPath/arterial_stiffness.json';
  static const String bloodPressure = '$_classificationsPath/blood_pressure.json';
  static const String bodyFatPercentage = '$_classificationsPath/body_fat_percentage.json';
  static const String bodyMassIndex = '$_classificationsPath/body_mass_index.json';
  static const String breathingRate = '$_classificationsPath/breathing_rate.json';
  static const String cardiovascularDisease = '$_classificationsPath/cardiovascular_disease.json';
  static const String centralObesity = '$_classificationsPath/central_obesity.json';
  static const String depression = '$_classificationsPath/depression.json';
  static const String framinghamCvd = '$_classificationsPath/framingham_cvd.json';
  static const String heartAttack = '$_classificationsPath/heart_attack.json';
  static const String inflammation = '$_classificationsPath/inflammation.json';
  static const String metabolicHealth = '$_classificationsPath/metabolic_health.json';
  static const String restingHeartRate = '$_classificationsPath/resting_heart_rate.json';
  static const String stroke = '$_classificationsPath/stroke.json';
  static const String waistToHeightRatio = '$_classificationsPath/waist_to_height_ratio.json';
  static const String waistToHipRatio = '$_classificationsPath/waist_to_hip_ratio.json';
  
  // Survey JSON Files
  static const String _surveysPath = '$_jsonPath/surveys';
  static const String surveyAnxiety = '$_surveysPath/survey_anxiety.json';
  static const String surveyDepression = '$_surveysPath/survey_depression.json';
  static const String surveyProfile = '$_surveysPath/survey_profile.json';
  static const String surveySchema = '$_surveysPath/survey_schema.json';
  
  // Calculation JSON Files
  static const String _calculationPath = '$_jsonPath/calculation/lipids_lookup';
  static const String cholesterol = '$_calculationPath/cholesterol.json';
  static const String hdlc = '$_calculationPath/hdlc.json';
  static const String ldlc = '$_calculationPath/ldlc.json';
  static const String triglycerides = '$_calculationPath/triglycerides.json';
  
  // Info Sheets
  static const String _infoSheetsPath = '$_basePath/info_sheets';
  static const String anxietyInfo = '$_infoSheetsPath/anxiety.html';
  static const String bodyFatPercentageInfo = '$_infoSheetsPath/body_fat_percentage.html';
  static const String breathingRateInfo = '$_infoSheetsPath/breathing_rate.html';
  static const String cardiacWorkloadInfo = '$_infoSheetsPath/cardiac_workload.html';
  static const String cardiovascularDiseaseInfo = '$_infoSheetsPath/cardiovascular_disease.html';
  static const String centralObesityInfo = '$_infoSheetsPath/central_obesity.html';
  static const String depressionInfo = '$_infoSheetsPath/depression.html';
  static const String heartAttackInfo = '$_infoSheetsPath/heart_attack.html';
  static const String heartRateInfo = '$_infoSheetsPath/heart_rate.html';
  static const String heartRateRecoveryInfo = '$_infoSheetsPath/heart_rate_recovery.html';
  static const String heartRateVariabilityInfo = '$_infoSheetsPath/heart_rate_variability.html';
  static const String hypertensionInfo = '$_infoSheetsPath/hypertension.html';
  static const String hypotensionInfo = '$_infoSheetsPath/hypotension.html';
  static const String irregularHeartbeatsInfo = '$_infoSheetsPath/irregular_heartbeats.html';
  static const String obesityInfo = '$_infoSheetsPath/obesity.html';
  static const String restingHeartRateInfo = '$_infoSheetsPath/resting_heart_rate.html';
  static const String stressInfo = '$_infoSheetsPath/stress.html';
  static const String strokeInfo = '$_infoSheetsPath/stroke.html';
  static const String waistCircumferenceInfo = '$_infoSheetsPath/waist_circumference.html';
  static const String waistToHeightRatioInfo = '$_infoSheetsPath/waist_to_height_ratio.html';
  static const String waistToHipRatioInfo = '$_infoSheetsPath/waist_to_hip_ratio.html';
  static const String infoStylesCss = '$_infoSheetsPath/styles.css';
}