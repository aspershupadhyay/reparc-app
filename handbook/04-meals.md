---
title: Meal planning and logging
status: proposed
owner: product-and-engineering
updated: 2026-10-05
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
