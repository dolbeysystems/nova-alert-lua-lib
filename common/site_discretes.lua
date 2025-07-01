---@diagnostic disable-next-line:name-style-check
local discrete_names = {}

-- local site_discretes = require("libs.common.site_discretes")


-- Anion Gap - Acidosis
discrete_names.dv_names_anion_gap = { "" }


-- Base Excess - Acidosis
discrete_names.dv_names_base_excess = { "BASE EXCESS (mmol/L)" }
-- Blood CO2 - Acidosis, Diabetes
discrete_names.dv_names_blood_co2 = { "CO2 (mmol/L)" }

-- Blood Glucose - Abnormal Serum Sodium, Acidosis, Encephalopathy, Sepis-Sirs, 
discrete_names.dv_names_blood_glucose = { "GLUCOSE (mg/dL)", "GLUCOSE" }
discrete_names.dv_names_blood_glucose_point_of_care = { "GLUCOSE ACCUCHECK (mg/dL)" }
-- Blood Loss - Anemia, Bleeding
discrete_names.dv_names_blood_loss = { "" }
-- Braden Acitivity Score -Functional Quadriplegia
discrete_names.dv_names_braden_activity_score = { "3.5 Activity (Braden Scale)" }
-- Braden Mobility Score - Functional Quadriplegia
discrete_names.dv_names_braden_mobility_score = { "3.5 Mobility" }
-- Braden Score - Pressure Ulcer
discrete_names.dv_names_braden_score = { "3.5 Braden Scale Total Points" }
-- CIWA Score - Substance Abuse
discrete_names.dv_names_ciwa_score = { "alcohol CIWA Calc score 1112" }
-- Cryoprecipitate Transfusion - Bleeding
discrete_names.dv_names_cryoprecipitate_transfusion = { "" }
-- DBP - Encephalopathy, Hypertensive Crisis, Pulmonary Edema, Severe Sepsis, Shock, Stroke
discrete_names.dv_names_dbp = { "BP Arterial Diastolic cc (mm Hg)", "DBP 3.5 (No Calculation) (mmhg)", "DBP 3.5 (No Calculation) (mm Hg)", "Diastolic Blood Pressure (mm Hg)" }
-- FiO2 - Acidosis
discrete_names.dv_names_fio2 = { "" }
-- HCO3 - Acidosis
discrete_names.dv_names_hco3 = { "HCO3 VENOUS (meq/L)" }

-- Heart Rate - Acidosis, Acute MI, Atrial Fibrillation, Cerebral Edema, COPD, Diabetes, Heart Failure, Hypertensive Crisis, 
--                  Pulmonary Edema, Pulmonary Embolism, Respiratory Failure, Rhabdomyolysis, Sepsis-SIRS, Severe Sepsis, Shock
discrete_names.dv_names_heart_rate = { "Heart Rate (bpm)", "Heart Rate cc (bpm)", "3.5 Heart Rate (Apical) (bpm)", "3.5 Heart Rate (Other) (bpm)", "3.5 Heart Rate (Radial) (bpm)", "SCC Monitor Pulse (bpm)" }

-- Hematocrit - Acute MI, Anemia, Bleeding, Pancytopenia, Shock, 
discrete_names.dv_names_hematocrit = { "HEMATOCRIT (%)", "HEMATOCRIT" }
-- Hemoglobin - Acute MI, Anemia, Bleeding, Pancytopenia, Sepsis-SIRS, Shock
discrete_names.dv_names_hemoglobin = { "HEMOGLOBIN (g/dL)", "HEMOGLOBIN" }

-- Glasgow Coma Score - Glasgow Library Script, Morbid Obesity
discrete_names.dv_names_glasgow_coma_scale = { "3.5 Neuro Glasgow Score" }
discrete_names.dv_names_glasgow_eye_opening = { "3.5 Neuro Glasgow Eyes (Adult)" }
discrete_names.dv_names_glasgow_verbal = { "3.5 Neuro Glasgow Verbal (Adult)" }
discrete_names.dv_names_glasgow_motor = { "3.5 Neuro Glasgow Motor" }
discrete_names.dv_names_oxygen_therapy = { "DELIVERY", "Device Type" }

-- INR - Bleeding
discrete_names.dv_names_inr = { "INR" }
-- Intracranial Pressure - Cerebral Edema
discrete_names.dv_names_intracranial_pressure = { "ICP cc (mm Hg)" }
-- MAP - Acidosis, Acute MI, Anemia, Atrial Fibrillation, Hypertensive Crisis, Kidney Disease Chronic, 
--           Kidney Failure Acute, Rhabdomyolysis, Sepsis-SIRS, Severe Sepsis, Shock
discrete_names.dv_names_map = { "Mean 3.5 (No Calculation) (mm Hg)", "MAP Invasive (mmHg)", "MAP Non-Invasive (Calculated) (mmHg)", "Mean 3.5 DI (mm Hg)", "BP Arterial Mean DI  CC (mmHg)" }
-- MCH -- Anemia,
discrete_names.dv_names_mch = { "MCH (pg)" }
-- MCV - Anemia
discrete_names.dv_names_mcv = { "MCV (fL)" }
-- MCHC - Anemia
discrete_names.dv_names_mchc = { "MCHC (g/dL)" }
-- Oxygen Flow Rate - COPD. Respiratory Failure
discrete_names.dv_names_oxygen_flow_rate = { "Oxygen Flow Rate (L/min)", "Resp O2 Delivery Flow Num" }
-- Oxygen Therapy - Acute MI, COPD, Diabetes, Pneumonia, Pulmanary Edema, Pulmonary Embolism, Respiratory Failure, Shock
discrete_names.dv_names_oxygen_therapy = { "DELIVERY", "Device Type", "FiO2" }
-- PaO2 - Acidosis, Acute MI, COPD, Encephalopathy, Morbid Obesity, Pneumonia, Pulmonary Edema, Pulmonary Embolism, 
--            Respiratory Failure, Sepsis-SIRS, Shock
discrete_names.dv_names_pao2 = { "BLD GAS O2 (mmHg)", "PO2 (mmHg)" }
-- PAO2/FIO2 Site Calculated - COPD, Respiratory Failure, Sepsis-SIRS
discrete_names.dv_names_pao2_fio2 = { "PO2/FiO2 (mmHg)" }

-- PCO2 - Acidosis, Encephalopathy, Morbid Obesity, Respiratory Failure, Sepsis-SIRS
discrete_names.dv_names_pco2 = { "pCO2 BldV (mm Hg)", "BLD GAS CO2 (mmHg)", "PaCO2 (mmHg)" }
-- PH - Acidosis, Diabetes, Encephalopathy, Morbid Obesity, Pulmonary Edema, Respiratory Failure
discrete_names.dv_names_ph = { "pH" }
-- Plasma Transfusion - Bleeding
discrete_names.dv_names_plasma_transfusion = { "Volume (mL)-Transfuse Plasma (mL)" }
-- Platelet Transfusion - Bleeding
discrete_names.dv_names_platelet_transfusion = { "" }
-- Pressure Injury Stage - Pressure Ulcer
discrete_names.dv_names_pressure_injury_stage = { "" }
-- PT - Bleeding
discrete_names.dv_names_pt = { "PROTIME (SEC)" }
-- PTT - Bleeding
discrete_names.dv_names_ptt = { "PTT (SEC)" }
-- RBC - Anemia
discrete_names.dv_names_rbc = { "RBC  (10X6/uL)" }
-- RDW - Anemia
discrete_names.dv_names_rdw = { "RDW CV (%)" }
-- Red Blood Cell Transfusion - Anemia
discrete_names.dv_names_red_blood_cell_transfusion = { "" }
-- Reticulocyte Count - Anemia
discrete_names.dv_names_reticulocyte_count = { "" }
-- Respiratory Rate - Acidosis, Cerebral Edema, COPD, Pneumonia, Pulmonary Edema, Pulmonary Embolism, Respiratory Failure, Sepsis-SIRS, Shock
discrete_names.dv_names_respiratory_rate = { "3.5 Respiratory Rate (#VS I&O) (per Minute)", "Respiratory Rate (per Minute)" }








-- SBP - Acidosis, Acute MI, Anemia, Atrial Fibrillation, Encephalopathy, Hypertensive Crisis, Kidney Disease Chronic,
--           Kidney Failure Acute, Pulmonary Edema, Rhabdomyolysis, Sepsis-SIRS, Severe Sepsis, Shock, Stroke, 
discrete_names.dv_names_sbp = { "SBP 3.5 (No Calculation) (mm Hg)", "BP Arterial Systolic cc (mm Hg)", "Systolic Blood Pressure (mm Hg)" }
-- Serum Bicarbonate - Acidosis, Diabetes, Respiratory Failure
discrete_names.dv_names_serum_bicarbonate = { "HCO3 (meq/L)", "HCO3 (mmol/L)" }
-- Serum Blood Urea Nitrogen(BUN) - Acidosis, Encephalopathy, Hypertensive Crisis, Kidney Disease Chronic, Kidney Failure Acute, Rhabdomyolysis, Sepsis-SIRS, Shock,
discrete_names.dv_names_serum_bun = { "BUN (mg/dL)" }
-- Serum Calcium - Encephalopathy
discrete_names.dv_names_serum_calcium = { "CALCIUM (mg/dL)" }
-- Serum Choloride - Acidosis
discrete_names.dv_names_serum_chloride = { "CHLORIDE (mmol/L)" }
-- Serum Creatinine - Acidosis, Encephalopathy, Sepsis-SIRS, Severe Sepsis, Shock,
discrete_names.dv_names_serum_creatinine = { "CREATININE (mg/dL)", "CREATININE SERUM (mg/dL)" }
-- Serum Ferritin - Anemia
discrete_names.dv_names_serum_ferritin = { "FERRITIN (ng/mL)" }
-- Serum Folate - Anemia
discrete_names.dv_names_serum_folate = { "" }
-- Serum Iron - Anemia
discrete_names.dv_names_serum_iron = { "IRON TOTAL (ug/dL)" }
-- Serum Ketone -- Acidosis
discrete_names.dv_names_serum_ketone = { "" }
-- Serum Lactate - Acidosis
discrete_names.dv_names_serum_lactate = { "LACTIC ACID (mmol/L)", "LACTATE (mmol/L)" }
-- Serum Potassium - Abnormal Serum Potassium, Acidosis
discrete_names.dv_names_serum_potassium = { "POTASSIUM (mmol/L)" }
-- Serum Sodium - Abnormal Serum Sodium, Acidosis
discrete_names.dv_names_serum_sodium = { "SODIUM (mmol/L)" }
-- SpO2 - Acidosis, Acute MI, COPD, Morbid Obesity, Pulmonary Edema, Respiratory Failure, Sepsis-SIRS, Severe Sepsis, 
discrete_names.dv_names_spo2 = { "Pulse Oximetry(Num) (%)", "Pulse Oximetry (%)" }
-- Temperature - Diabetes, Encephalopathy, Kidney Disease Chronic, Kidney Failure Acute, Pneumonia, Rhabdomyolysis, Sepsis-SIRS, Shock, UTI
discrete_names.dv_names_temperature = { "Temperature Degrees C 3.5 (degrees C)", "Temperature  Degrees C 3.5 (degrees C)", "TEMPERATURE (C)" }
-- Transferrin - Anemia
discrete_names.dv_names_transferrin = { "TRANSFERRIN" }
-- Total Iron Binding Capacity - Anemia
discrete_names.dv_names_total_iron_binding_capacity = { "IRON BINDING" }
-- Troponin T High Sensitivity - Acute MI, Heart Failure, Hypertensive Crisis, Pulmonary Edema
discrete_names.dv_names_troponin_t = { "TROPONIN, HIGH SENSITIVITY (ng/L)" }
-- Urine Ketones - Acidosis, Diabetes
discrete_names.dv_names_urine_ketones = { "UR KETONES (mg/dL)", "KETONES (mg/dL)" }
-- Venous Blood CO2 - Acidosis
discrete_names.dv_names_venous_blood_co2 = { "BLD GAS CO2 VEN (mmHg)" }
-- Venous PH - Acidosis, Morbid Obesity
discrete_names.dv_names_venous_ph = { "pH (VENOUS)", "pH VENOUS" }
-- Vitamin B12 - Anemia
discrete_names.dv_names_vitamin_b12 = { "VITAMIN B12 (pg/mL)" }
-- WBC - Anemia, Pancytopenia, Pneumonia, Sepsis-SIRS, UTI
discrete_names.dv_names_wbc = { "WBC (10x3/ul)" }


return discrete_names
