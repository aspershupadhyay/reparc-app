#!/usr/bin/env python3
"""Builds the bundled food list from USDA FoodData Central (SR Legacy).

Source: U.S. Department of Agriculture, Agricultural Research Service.
FoodData Central, SR Legacy, April 2018 release.
https://fdc.nal.usda.gov/  License: public domain (CC0 1.0).

Each food keeps its FDC ID so anyone can check the values at
https://fdc.nal.usda.gov/food-details/<fdcId>/nutrients

Output:
  assets/foods/foods.json   values per 100 g and a usual portion in grams

Run from the app/ folder:
  python3 tool/food_library/build.py
"""
import csv
import io
import json
import pathlib
import urllib.request
import zipfile

URL = "https://fdc.nal.usda.gov/fdc-datasets/FoodData_Central_sr_legacy_food_csv_2018-04.zip"
APP = pathlib.Path(__file__).resolve().parents[2]
OUT = APP / "assets" / "foods" / "foods.json"

# Nutrient IDs in FoodData Central.
NUTRIENTS = {
    "kcal": "1008",
    "protein": "1003",
    "carbs": "1005",
    "fiber": "1079",
    "fat": "1004",
    "sugar": "2000",
    "sodium": "1093",
}

# (key, FDC ID, name shown in the app, diet tag, group, usual portion g, portion words)
# Diet tags: plant, dairy, egg, fish, meat.
FOODS = [
    # Protein foods
    ("chicken-breast", 171477, "Chicken breast, roasted", "meat", "protein", 150, "1 breast fillet"),
    ("chicken-thigh", 172388, "Chicken thigh, roasted", "meat", "protein", 120, "1 large thigh"),
    ("beef-mince-90", 174031, "Lean beef mince (90%), cooked", "meat", "protein", 120, "1 patty"),
    ("pork-tenderloin", 168250, "Pork tenderloin, roasted", "meat", "protein", 120, "1 portion"),
    ("salmon", 175168, "Salmon, cooked", "fish", "protein", 140, "1 fillet"),
    ("tuna-can", 171986, "Tuna in water, drained", "fish", "protein", 100, "1 small can"),
    ("cod", 171956, "Cod, cooked", "fish", "protein", 150, "1 fillet"),
    ("tilapia", 175177, "Tilapia, cooked", "fish", "protein", 150, "1 fillet"),
    ("shrimp", 175180, "Shrimp, cooked", "fish", "protein", 100, "1 portion"),
    ("egg", 173424, "Egg, hard-boiled", "egg", "protein", 50, "1 large egg"),
    ("egg-white", 172183, "Egg white, raw", "egg", "protein", 33, "1 egg white"),
    ("greek-yogurt", 170894, "Greek yogurt, plain, non-fat", "dairy", "protein", 170, "1 small pot"),
    ("yogurt-low-fat", 170886, "Yogurt, plain, low-fat (curd / dahi)", "dairy", "protein", 150, "1 bowl"),
    ("cottage-cheese", 172182, "Cottage cheese, 2%", "dairy", "protein", 115, "1/2 cup"),
    ("ricotta", 171248, "Ricotta, part-skim", "dairy", "protein", 60, "1/4 cup"),
    ("mozzarella", 170847, "Mozzarella, part-skim", "dairy", "protein", 30, "1 slice"),
    ("milk-skim", 171269, "Milk, skim", "dairy", "protein", 240, "1 glass"),
    ("milk-whole", 171265, "Milk, whole", "dairy", "protein", 240, "1 glass"),
    ("whey", 173180, "Whey protein powder", "dairy", "protein", 30, "1 scoop"),
    ("tofu", 172448, "Tofu, firm", "plant", "protein", 125, "1/2 block"),
    ("tempeh", 172467, "Tempeh, cooked", "plant", "protein", 100, "1 portion"),
    ("edamame", 168411, "Edamame, cooked", "plant", "protein", 155, "1 cup"),
    ("soy-protein", 173181, "Soy protein powder", "plant", "protein", 30, "1 scoop"),
    ("soy-milk", 172446, "Soy milk, unsweetened", "plant", "protein", 240, "1 glass"),
    # Pulses
    ("lentils", 172421, "Lentils (dal), boiled", "plant", "legume", 200, "1 cup cooked"),
    ("chickpeas", 173757, "Chickpeas (chana), boiled", "plant", "legume", 160, "1 cup cooked"),
    ("kidney-beans", 173740, "Kidney beans (rajma), boiled", "plant", "legume", 175, "1 cup cooked"),
    ("black-beans", 173735, "Black beans, boiled", "plant", "legume", 170, "1 cup cooked"),
    ("mung-beans", 174257, "Mung beans (moong), boiled", "plant", "legume", 200, "1 cup cooked"),
    ("pigeon-peas", 172437, "Pigeon peas (toor dal), boiled", "plant", "legume", 170, "1 cup cooked"),
    ("hummus", 174289, "Hummus", "plant", "legume", 60, "4 tbsp"),
    ("besan", 174288, "Chickpea flour (besan)", "plant", "legume", 30, "1/4 cup"),
    # Grains and starches
    ("oats", 173904, "Oats, dry", "plant", "grain", 40, "1/2 cup dry"),
    ("rice-white", 168878, "White rice, cooked", "plant", "grain", 160, "1 cup cooked"),
    ("rice-brown", 169704, "Brown rice, cooked", "plant", "grain", 160, "1 cup cooked"),
    ("quinoa", 168917, "Quinoa, cooked", "plant", "grain", 185, "1 cup cooked"),
    ("millet", 168871, "Millet, cooked", "plant", "grain", 175, "1 cup cooked"),
    ("couscous", 169700, "Couscous, cooked", "plant", "grain", 160, "1 cup cooked"),
    ("pasta", 169737, "Pasta, cooked", "plant", "grain", 140, "1 cup cooked"),
    ("pasta-wholewheat", 168910, "Whole-wheat pasta, cooked", "plant", "grain", 140, "1 cup cooked"),
    ("bread-wholewheat", 172688, "Whole-wheat bread", "plant", "grain", 32, "1 slice"),
    ("bread-white", 174924, "White bread", "plant", "grain", 27, "1 slice"),
    ("roti", 174075, "Roti / chapati, whole wheat", "plant", "grain", 40, "1 roti"),
    ("tortilla-corn", 173241, "Corn tortilla", "plant", "grain", 26, "1 tortilla"),
    ("potato", 170093, "Potato, baked with skin", "plant", "grain", 175, "1 medium"),
    ("sweet-potato", 168483, "Sweet potato, baked", "plant", "grain", 150, "1 medium"),
    # Vegetables
    ("broccoli", 169967, "Broccoli, boiled", "plant", "veg", 90, "1 cup"),
    ("spinach-cooked", 168463, "Spinach, cooked", "plant", "veg", 90, "1/2 cup"),
    ("spinach", 168462, "Spinach, raw", "plant", "veg", 30, "1 cup"),
    ("kale", 168421, "Kale, raw", "plant", "veg", 20, "1 cup"),
    ("romaine", 169247, "Romaine lettuce", "plant", "veg", 50, "1 cup"),
    ("carrot", 170393, "Carrot, raw", "plant", "veg", 60, "1 medium"),
    ("tomato", 170457, "Tomato, raw", "plant", "veg", 120, "1 medium"),
    ("cucumber", 168409, "Cucumber, raw", "plant", "veg", 100, "1/2 cucumber"),
    ("red-pepper", 170108, "Red pepper, raw", "plant", "veg", 120, "1 pepper"),
    ("mushrooms", 169251, "Mushrooms, raw", "plant", "veg", 70, "1 cup"),
    ("onion", 170000, "Onion, raw", "plant", "veg", 110, "1 medium"),
    ("cauliflower", 170397, "Cauliflower, boiled", "plant", "veg", 125, "1 cup"),
    ("green-beans", 169141, "Green beans, boiled", "plant", "veg", 125, "1 cup"),
    ("peas", 170017, "Green peas, boiled", "plant", "veg", 80, "1/2 cup"),
    # Fruit
    ("banana", 173944, "Banana", "plant", "fruit", 118, "1 medium"),
    ("apple", 171688, "Apple, with skin", "plant", "fruit", 180, "1 medium"),
    ("orange", 169097, "Orange", "plant", "fruit", 130, "1 medium"),
    ("blueberries", 171711, "Blueberries", "plant", "fruit", 150, "1 cup"),
    ("strawberries", 167762, "Strawberries", "plant", "fruit", 150, "1 cup"),
    ("mango", 169910, "Mango", "plant", "fruit", 165, "1 cup"),
    ("grapes", 174683, "Grapes", "plant", "fruit", 150, "1 cup"),
    ("pineapple", 169124, "Pineapple", "plant", "fruit", 165, "1 cup"),
    ("papaya", 169926, "Papaya", "plant", "fruit", 145, "1 cup"),
    ("dates", 168191, "Dates, medjool", "plant", "fruit", 24, "1 date"),
    # Fats, nuts, seeds
    ("avocado", 171705, "Avocado", "plant", "fat", 100, "1/2 avocado"),
    ("olive-oil", 171413, "Olive oil", "plant", "fat", 14, "1 tbsp"),
    ("ghee", 173412, "Ghee (butter oil)", "dairy", "fat", 13, "1 tbsp"),
    ("almonds", 170567, "Almonds", "plant", "nuts", 28, "1 handful (23 nuts)"),
    ("walnuts", 170187, "Walnuts", "plant", "nuts", 28, "1 handful"),
    ("peanuts", 173806, "Peanuts, dry-roasted", "plant", "nuts", 28, "1 handful"),
    ("peanut-butter", 172470, "Peanut butter", "plant", "nuts", 32, "2 tbsp"),
    ("chia", 170554, "Chia seeds", "plant", "nuts", 12, "1 tbsp"),
    ("flax", 169414, "Flaxseed", "plant", "nuts", 10, "1 tbsp"),
    ("pumpkin-seeds", 170556, "Pumpkin seeds", "plant", "nuts", 28, "1 handful"),
    ("hemp", 170148, "Hemp seeds, hulled", "plant", "nuts", 30, "3 tbsp"),
    ("sunflower-seeds", 170563, "Sunflower seeds", "plant", "nuts", 28, "1 handful"),
    ("honey", 169640, "Honey", "plant", "extra", 21, "1 tbsp"),
    ("almond-milk", 174832, "Almond milk, unsweetened", "plant", "extra", 240, "1 glass"),
]


def main():
    print("Downloading", URL)
    data = urllib.request.urlopen(URL).read()
    z = zipfile.ZipFile(io.BytesIO(data))
    root = next(n.split("/")[0] for n in z.namelist() if n.endswith("food.csv"))

    def rows(name):
        return csv.DictReader(io.TextIOWrapper(z.open(f"{root}/{name}"), encoding="utf-8"))

    wanted = {str(f[1]) for f in FOODS}
    desc = {r["fdc_id"]: r["description"] for r in rows("food.csv") if r["fdc_id"] in wanted}
    missing = wanted - desc.keys()
    if missing:
        raise SystemExit(f"FDC IDs not found: {sorted(missing)}")
    by_id = {v: k for k, v in NUTRIENTS.items()}
    values = {}
    for r in rows("food_nutrient.csv"):
        if r["fdc_id"] in wanted and r["nutrient_id"] in by_id:
            values.setdefault(r["fdc_id"], {})[by_id[r["nutrient_id"]]] = round(float(r["amount"]), 2)

    foods = []
    for key, fdc, name, diet, group, grams, words in FOODS:
        v = values.get(str(fdc), {})
        if "kcal" not in v or "protein" not in v:
            raise SystemExit(f"{key}: energy or protein missing")
        foods.append(
            {
                "id": key,
                "name": name,
                "fdcId": fdc,
                "usdaName": desc[str(fdc)],
                "diet": diet,
                "group": group,
                "portionG": grams,
                "portion": words,
                # Per 100 g. A missing nutrient is left out, never written as 0.
                "per100g": {k: v[k] for k in NUTRIENTS if k in v},
            }
        )
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(
        json.dumps(
            {
                "source": "USDA FoodData Central, SR Legacy (April 2018)",
                "sourceUrl": "https://fdc.nal.usda.gov/",
                "license": "Public domain (CC0 1.0)",
                "foods": foods,
            },
            indent=1,
            ensure_ascii=False,
        )
        + "\n"
    )
    print(f"Wrote {len(foods)} foods to {OUT}")


if __name__ == "__main__":
    main()
