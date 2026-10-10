"""India foods for the bundled food list (owner direction 2026-10-10: foods
by country, India first; data choice: USDA plus marked estimates).

Three kinds of entry:

- ``("fndds", fdc_id)``: a dish from USDA FNDDS (survey foods, public
  domain). Values are USDA's own.
- ``("sr", fdc_id)``: an ingredient from USDA SR Legacy (public domain).
- ``("sr", fdc_id, basis)``: a stand-in: the values of a close USDA food,
  marked as an estimate, with [basis] saying which food. An optional fourth
  item names nutrients to leave out, where the stand-in differs.
- ``("recipe", [(fdc_id, grams), ...], cooked_grams)``: a dish USDA does not
  have. Values are computed from USDA ingredients and the cooked weight, and
  the app marks them as estimates. Recipes add no salt, so their sodium is
  left out (missing, not zero). The recipe is written into foods.json so
  anyone can check it.

Portions are household sizes. Where USDA FNDDS gives a gram weight (a
medium roti 40 g, an idli 38 g), that weight is used. A katori is 150 g of a
cooked dish (a common steel katori holds about 150 ml).

Fields: key, source, name, diet, group, portions [(words, grams)]. The first
portion is the usual one.
Diet tags: plant, dairy, egg, fish, meat.
"""

# SR Legacy and FNDDS ingredient IDs used in recipes.
RICE_RAW = 168877
RICE_COOKED = 168878
CHICKPEAS_BOILED = 173757
KIDNEY_BOILED = 175194
URAD_RAW = 174259
MOONG_RAW = 174256
BESAN = 174288
SOY_FLOUR_DEFATTED = 174275
POTATO_BOILED = 170440
ONION = 170000
TOMATO = 170457
CUCUMBER = 168409
PEANUTS = 173806
SUGAR = 169655
MILK_WHOLE = 171265
CURD_WHOLE = 171284
CREAM = 170859
BUTTER = 173430
OIL_PEANUT = 171410
GHEE = 173412
EGG = 173424
CHICKEN_LEG = 172380
# FNDDS "Cheese, paneer" (2705740) lists 22 g sugar per 100 g, which does
# not fit plain paneer, so paneer uses queso fresco, a similar fresh cheese.
PANEER = 172223
TEA_WITH_MILK = 2710506
PARATHA = 2707715

KATORI = 150

FOODS = [
    # Breads
    ("roti-medium", ("fndds", 2707713), "Roti / chapati", "plant", "grain",
     [("1 roti (7 in)", 40), ("1 small roti", 27), ("1 large roti", 52)]),
    ("paratha", ("fndds", 2707715), "Paratha, plain", "plant", "grain", [("1 paratha", 70)]),
    ("aloo-paratha", ("recipe", [(PARATHA, 70), (POTATO_BOILED, 45), (OIL_PEANUT, 3)], 115),
     "Aloo paratha", "plant", "grain", [("1 paratha", 115)]),
    ("puri", ("fndds", 2707714), "Puri", "plant", "grain", [("1 puri", 36)]),
    ("naan", ("fndds", 2707613), "Naan", "dairy", "grain", [("1/4 naan", 44), ("1 whole naan", 177)]),
    # South Indian and breakfast
    ("idli", ("fndds", 2708346), "Idli", "plant", "grain", [("1 idli", 38), ("2 idli", 76)]),
    ("dosa", ("fndds", 2708347), "Dosa, plain", "plant", "grain", [("1 medium dosa", 80), ("1 large dosa", 155)]),
    ("masala-dosa", ("fndds", 2709129), "Masala dosa", "plant", "dish", [("1 medium dosa", 267), ("1 small dosa", 113)]),
    ("upma", ("fndds", 2709128), "Upma", "plant", "dish", [("1 katori", KATORI), ("1 cup", 170)]),
    ("vada", ("fndds", 2709130), "Vada (medu vada)", "plant", "dish", [("1 vada", 30), ("2 vada", 60)]),
    ("sambar", ("fndds", 2707430), "Sambar", "plant", "legume", [("1 katori", KATORI)]),
    ("poha", ("recipe", [(RICE_RAW, 60), (ONION, 30), (POTATO_BOILED, 30), (PEANUTS, 10), (OIL_PEANUT, 7)], 200),
     "Poha", "plant", "dish", [("1 plate", 200), ("1 katori", KATORI)]),
    ("besan-chilla", ("recipe", [(BESAN, 40), (ONION, 20), (TOMATO, 20), (OIL_PEANUT, 5)], 110),
     "Besan chilla", "plant", "dish", [("1 chilla", 110)]),
    ("moong-chilla", ("recipe", [(MOONG_RAW, 50), (ONION, 20), (OIL_PEANUT, 5)], 120),
     "Moong dal chilla", "plant", "dish", [("1 chilla", 120)]),
    ("chutney", ("fndds", 2709309), "Sweet chutney (mango / tamarind)", "plant", "extra", [("1 tbsp", 20), ("2 tbsp", 40)]),
    # Rice
    ("rice-plain", ("fndds", 2708408), "Rice, plain (chawal)", "plant", "grain", [("1 katori", KATORI), ("1 cup", 160)]),
    ("jeera-rice", ("recipe", [(RICE_COOKED, 150), (GHEE, 5)], 155), "Jeera rice", "dairy", "grain",
     [("1 katori", KATORI)]),
    ("veg-pulao", ("fndds", 2709007), "Veg pulao (rice with peas and carrots)", "plant", "grain", [("1 katori", KATORI)]),
    ("khichdi", ("fndds", 2709030), "Khichdi (rice with lentils)", "plant", "dish", [("1 katori", KATORI), ("1 plate", 250)]),
    ("curd-rice", ("recipe", [(RICE_COOKED, 150), (CURD_WHOLE, 100), (OIL_PEANUT, 3)], 253), "Curd rice",
     "dairy", "dish", [("1 katori", KATORI), ("1 plate", 250)]),
    ("biryani-chicken", ("fndds", 2706538), "Chicken biryani", "meat", "dish", [("1 plate", 300), ("1 katori", KATORI)]),
    ("biryani-mutton", ("fndds", 2706490), "Mutton biryani", "meat", "dish", [("1 plate", 300), ("1 katori", KATORI)]),
    ("biryani-veg", ("fndds", 2708985), "Veg biryani", "plant", "dish", [("1 plate", 300), ("1 katori", KATORI)]),
    # Dal and pulses
    ("dal", ("fndds", 2707427), "Dal (tadka / plain)", "plant", "legume", [("1 katori", KATORI)]),
    ("dal-chawal", ("fndds", 2707432), "Dal chawal (lentil curry with rice)", "plant", "dish",
     [("1 plate", 300), ("1 katori", KATORI)]),
    ("dal-makhani", ("recipe", [(URAD_RAW, 50), (KIDNEY_BOILED, 30), (TOMATO, 40), (BUTTER, 10), (CREAM, 15)], 300),
     "Dal makhani", "dairy", "legume", [("1 katori", KATORI)]),
    ("chole", ("recipe", [(CHICKPEAS_BOILED, 160), (ONION, 40), (TOMATO, 60), (OIL_PEANUT, 10)], 280),
     "Chole (chickpea curry)", "plant", "legume", [("1 katori", KATORI)]),
    ("rajma", ("recipe", [(KIDNEY_BOILED, 175), (ONION, 40), (TOMATO, 60), (OIL_PEANUT, 10)], 290),
     "Rajma (kidney bean curry)", "plant", "legume", [("1 katori", KATORI)]),
    ("lobia", ("sr", 173759), "Lobia (black-eyed beans), boiled", "plant", "legume", [("1 katori", KATORI)]),
    ("sprouts", ("sr", 169957), "Moong sprouts", "plant", "legume", [("1 katori", 100)]),
    ("chana-saag", ("fndds", 2709632), "Chana saag", "plant", "legume", [("1 katori", KATORI)]),
    ("urad-dal-dry", ("sr", URAD_RAW), "Urad dal, dry", "plant", "legume", [("1/4 cup dry", 50)]),
    ("moong-dal-dry", ("sr", MOONG_RAW), "Moong dal, dry", "plant", "legume", [("1/4 cup dry", 50)]),
    ("masoor-dal-dry", ("sr", 172420), "Masoor dal, dry", "plant", "legume", [("1/4 cup dry", 50)]),
    ("toor-dal-dry", ("sr", 172436), "Toor dal, dry", "plant", "legume", [("1/4 cup dry", 50)]),
    ("chana-dry", ("sr", 173756), "Chana (chickpeas), dry", "plant", "legume", [("1/4 cup dry", 50)]),
    ("soya-chunks", ("sr", SOY_FLOUR_DEFATTED, "Value from defatted soy flour, which soya chunks are made from"),
     "Soya chunks, dry", "plant",
     "protein", [("1 handful dry", 30), ("1/2 cup dry", 50)]),
    ("soya-curry", ("recipe", [(SOY_FLOUR_DEFATTED, 30), (ONION, 30), (TOMATO, 40), (OIL_PEANUT, 7)], 200),
     "Soya chunk curry", "plant", "protein", [("1 katori", KATORI)]),
    # Paneer, dairy
    ("paneer", ("sr", PANEER, "Value from queso fresco, a similar fresh cheese; queso fresco is salted, so sodium is left out", ("sodium",)), "Paneer", "dairy", "protein", [("100 g", 100), ("1 cube (2 cm)", 15)]),
    ("palak-paneer", ("fndds", 2709631), "Palak paneer", "dairy", "dish", [("1 katori", KATORI)]),
    ("paneer-bhurji", ("recipe", [(PANEER, 100), (ONION, 30), (TOMATO, 30), (OIL_PEANUT, 7)], 160),
     "Paneer bhurji", "dairy", "protein", [("1 katori", KATORI)]),
    ("curd", ("fndds", 2705418), "Curd (dahi), whole milk", "dairy", "protein", [("1 katori", KATORI)]),
    ("raita", ("recipe", [(CURD_WHOLE, 100), (CUCUMBER, 30)], 130), "Raita", "dairy", "extra", [("1 katori", 130)]),
    ("lassi-sweet", ("recipe", [(CURD_WHOLE, 200), (SUGAR, 15)], 265), "Lassi, sweet", "dairy", "extra",
     [("1 glass", 265)]),
    ("chaas", ("fndds", 2705393), "Chaas (buttermilk)", "dairy", "extra", [("1 glass", 244)]),
    ("buffalo-milk", ("sr", 171280), "Buffalo milk", "dairy", "protein", [("1 glass", 244)]),
    ("chai", ("fndds", TEA_WITH_MILK), "Chai with milk, no sugar", "dairy", "extra", [("1 cup", 150)]),
    ("chai-sugar", ("recipe", [(TEA_WITH_MILK, 150), (SUGAR, 8)], 158), "Chai with milk and sugar", "dairy",
     "extra", [("1 cup", 158)]),
    ("kheer", ("recipe", [(MILK_WHOLE, 500), (RICE_RAW, 30), (SUGAR, 30)], 350), "Kheer", "dairy", "extra",
     [("1 katori", KATORI)]),
    # Eggs, chicken, mutton, fish
    ("egg-bhurji", ("fndds", 2707200), "Egg bhurji / omelette, with oil", "egg", "protein",
     [("2 eggs", 110), ("3 eggs", 165)]),
    ("egg-curry", ("recipe", [(EGG, 100), (ONION, 40), (TOMATO, 60), (OIL_PEANUT, 10)], 200), "Egg curry", "egg",
     "protein", [("1 katori (2 eggs)", 200)]),
    ("chicken-curry", ("fndds", 2706437), "Chicken curry", "meat", "protein", [("1 katori", KATORI)]),
    ("tandoori-chicken", ("recipe", [(CHICKEN_LEG, 100), (CURD_WHOLE, 20), (OIL_PEANUT, 3)], 115),
     "Tandoori chicken", "meat", "protein", [("1 leg piece", 115), ("2 pieces", 230)]),
    ("mutton", ("sr", 175304), "Mutton (goat), cooked", "meat", "protein", [("100 g", 100)]),
    ("mutton-curry", ("fndds", 2706413), "Mutton curry", "meat", "protein", [("1 katori", KATORI)]),
    ("fish-curry", ("fndds", 2706460), "Fish curry", "fish", "protein", [("1 katori", KATORI)]),
    ("fish-carp", ("sr", 174185), "Rohu / carp, cooked", "fish", "protein", [("1 piece", 100)]),
    # Vegetables (sabzi)
    ("aloo-sabzi", ("recipe", [(POTATO_BOILED, 200), (ONION, 30), (TOMATO, 30), (OIL_PEANUT, 10)], 270),
     "Aloo sabzi", "plant", "veg", [("1 katori", KATORI)]),
    ("bhindi", ("fndds", 2709947), "Bhindi (okra) sabzi", "plant", "veg", [("1 katori", 100)]),
    ("baingan", ("fndds", 2709930), "Baingan (eggplant) sabzi", "plant", "veg", [("1 katori", 100)]),
    ("gobi", ("fndds", 2709902), "Gobi (cauliflower) sabzi", "plant", "veg", [("1 katori", 100)]),
    ("palak", ("fndds", 2709618), "Palak (spinach) sabzi", "plant", "veg", [("1 katori", 100)]),
    ("mixed-veg", ("fndds", 2710067), "Mixed veg curry", "plant", "veg", [("1 katori", KATORI)]),
    ("lauki", ("sr", 169233), "Lauki (bottle gourd), boiled", "plant", "veg", [("1 katori", KATORI)]),
    ("karela", ("sr", 168393), "Karela (bitter gourd), raw", "plant", "veg", [("1 medium", 100)]),
    # Snacks and sweets
    ("samosa", ("fndds", 2708730), "Samosa", "plant", "extra", [("1 samosa", 100), ("1 small samosa", 25)]),
    ("pakora", ("fndds", 2710066), "Pakora", "plant", "extra", [("1 pakora", 12), ("1 plate (4)", 48)]),
    ("papad", ("fndds", 2707429), "Papad, roasted", "plant", "extra", [("1 papad", 9)]),
    ("ladoo", ("fndds", 2710351), "Ladoo", "dairy", "extra", [("1 ladoo", 60)]),
    ("makhana", ("sr", 170149), "Makhana (lotus seeds), dry", "plant", "nuts", [("1 cup", 30)]),
    ("cashews", ("sr", 170571), "Cashews, roasted", "plant", "nuts", [("1 handful", 28)]),
    ("coconut", ("sr", 170169), "Coconut, fresh", "plant", "nuts", [("1 piece (2 in)", 45)]),
    # Flours and grains
    ("atta", ("sr", 168893), "Atta (whole-wheat flour)", "plant", "grain", [("1/4 cup", 30)]),
    ("maida", ("sr", 168894), "Maida (white flour)", "plant", "grain", [("1/4 cup", 30)]),
    ("sooji", ("sr", 169715), "Sooji / rava (semolina)", "plant", "grain", [("1/4 cup", 40)]),
    ("rice-raw", ("sr", RICE_RAW), "Rice, raw", "plant", "grain", [("1/4 cup", 45)]),
    ("sabudana", ("sr", 169717), "Sabudana (tapioca pearls), dry", "plant", "grain", [("1/4 cup", 40)]),
    ("jowar", ("sr", 169716), "Jowar (sorghum), dry", "plant", "grain", [("1/4 cup", 50)]),
    ("bajra", ("sr", 168871), "Bajra (millet), cooked", "plant", "grain", [("1 katori", KATORI)]),
    ("makki-atta", ("sr", 169697), "Makki atta (cornmeal)", "plant", "grain", [("1/4 cup", 30)]),
    # Fruit
    ("guava", ("sr", 173044), "Guava (amrood)", "plant", "fruit", [("1 medium", 100)]),
    ("pomegranate", ("sr", 169134), "Pomegranate (anar)", "plant", "fruit", [("1/2 fruit", 140)]),
    ("chikoo", ("sr", 167759), "Chikoo (sapodilla)", "plant", "fruit", [("1 chikoo", 100)]),
    ("jackfruit", ("sr", 174687), "Jackfruit (kathal), ripe", "plant", "fruit", [("1 cup", 165)]),
    # Oils
    ("mustard-oil", ("sr", 172337), "Mustard oil", "plant", "fat", [("1 tbsp", 14), ("1 tsp", 5)]),
    ("groundnut-oil", ("sr", OIL_PEANUT), "Groundnut oil", "plant", "fat", [("1 tbsp", 14), ("1 tsp", 5)]),
    ("coconut-oil", ("sr", 171412), "Coconut oil", "plant", "fat", [("1 tbsp", 14), ("1 tsp", 5)]),
]
