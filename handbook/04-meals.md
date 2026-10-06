---
title: Meal planning and logging
status: proposed
owner: product-and-engineering
updated: 2026-10-06
---

# Section 5: Meal planning and logging

## 5.1 Purpose

Help a user plan meals and record food. Show the source and limits of each nutrition value.

## 5.2 User flow

1. Open Meal.
2. Select a date and meal slot.
3. Select a saved food or enter a custom food.
4. Enter the amount and unit.
5. Review the values and source.
6. Save the meal.
7. Open, edit, or remove the saved meal later.

The app must save a custom meal offline.

## 5.3 Food and serving data

A food entry can contain:

- Name and optional brand.
- Amount eaten.
- Unit used for that amount.
- Nutrient values that are known.
- Source of each value.
- Date the source was checked.
- Optional notes.

Keep the amount eaten separate from the source serving size. Keep missing values as missing. Do not store a missing value as zero.

## 5.4 Food sources

Start with manual entry and user-saved foods. Add a food database or barcode lookup only after review of:

- Data quality and coverage.
- Data license and attribution.
- Provider cost and service limits.
- User privacy and data sent to the provider.
- How users correct bad values.

Do not copy a food database without permission.

## 5.5 Nutrition display

Show energy and nutrient values only when the record has those values. Mark estimates as estimates. Do not claim exactness without evidence from the source.

Let users hide calorie views. Do not set a target without the user's choice. Do not present a target as medical advice.

## 5.6 Meal plan

Let users add, rename, and remove meal slots. A plan is not a food log. Clearly distinguish a planned meal from a meal the user marked as eaten.

The image 1 layout informs the daily summary, date selector, macro display, meal timeline, and meal cards. Use the shared design system.

## 5.7 Suggestions and AI

Suggestions are optional. Show why a suggestion appears and which user data it used. Ask the user before a suggestion changes a plan or log.

Do not turn a food image into a saved record without review. Do not send meal records to an AI provider without clear consent.

## 5.8 Limits

The app is not a dietitian or medical service. It must not give treatment advice. Do not use food logs to infer a medical condition.

## 5.9 AI context

- **Purpose:** Plan and record meals without hiding uncertainty.
- **Flow:** Choose date, choose slot, add food, set amount, review, save, edit.
- **Data:** Keep serving, unit, source, and checked date.
- **AI:** Ask before a suggestion changes a record.
- **Safety:** Unknown is not zero. An estimate is not a fact.
- **Done when:** A custom meal can be logged offline and edited later.
- **To confirm:** Food database, barcode provider, supported nutrients, and target options.

## 5.10 Nutrients, targets, food list, and day plans

Built 2026-10-06 (D-021).

**Nutrients.** Each food can record energy (kcal), protein, carbs, fibre, fat, sugar (g), and sodium (mg). Empty is not zero. Old entries have no fibre, sugar, or sodium value.

**Targets.** Me → Body and goals. The user enters sex, age, height, weight, activity, goal, and diet. Targets show only when the user turns them on. Code: `app/lib/domain/targets.dart`.

| Target | Rule | Source |
|---|---|---|
| Energy | Mifflin-St Jeor resting energy × activity factor (1.2–1.9); −20% to lose fat, +10% to build muscle | Mifflin et al. 1990 |
| Protein | 1.6 g/kg to stay the same, 1.8 to build, 2.0 to lose fat; +0.2 g/kg vegan; user can set 1.2–2.4 | Morton et al. 2018; ISSN 2017 |
| Fibre | 14 g per 1,000 kcal | Dietary Guidelines for Americans 2020–2025 |
| Fat | About 25% of energy, at least 0.6 g/kg | Dietary Reference Intakes (AMDR 20–35%) |
| Carbs | The energy left after protein and fat | AMDR 45–65% |
| Sugar | Stay under 10% of energy (labels include fruit and milk sugar, so this is a loose guide) | WHO 2015 |
| Sodium | Stay under 2,000 mg | WHO 2023 |

Protein needs only body weight. The rest needs the full profile.

**Food list.** "Find a food" searches the user's foods and 84 common foods from USDA FoodData Central SR Legacy, per 100 g, with each FDC ID as the source. The list respects the user's diet. Build: `app/tool/food_library/build.py`.

**Plan my day.** Meal → Plan my day picks a breakfast, lunch, snack, and dinner the diet allows (mixed, vegetarian + eggs, vegetarian, or vegan), scales portions toward the energy target (60–160%), and adds a lean protein top-up when protein is more than 5% short. The user can shuffle. Nothing is saved until the user taps Add; then the foods go in as **planned**, not eaten. Code: `app/lib/domain/meal_plan.dart`.

**To confirm:** Dietitian review of meal ideas and target rules; a barcode or online food database.
