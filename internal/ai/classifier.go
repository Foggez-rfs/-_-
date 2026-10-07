package ai

import "strings"

type Category string

const (
CatCleaning Category = "уборка"
CatPlumbing Category = "сантехника"
CatElectric Category = "электрика"
CatDelivery Category = "доставка"
CatRepair   Category = "ремонт"
CatAssist   Category = "сопровождение"
CatOther    Category = "прочее"
)

// ClassifyOrder — rule-based классификатор
func ClassifyOrder(text string) (Category, int) {
t := strings.ToLower(text)

urgent := []string{"срочно", "авария", "затопило", "прорвало", "пожар", "горит", "замыкает"}
for _, k := range urgent {
if strings.Contains(t, k) {
if strings.Contains(t, "кран") || strings.Contains(t, "вода") || strings.Contains(t, "труб") {
return CatPlumbing, 1
}
if strings.Contains(t, "провод") || strings.Contains(t, "розетк") || strings.Contains(t, "свет") {
return CatElectric, 1
}
return CatOther, 1
}
}

rules := map[Category][]string{
CatCleaning: {"убор", "пылесос", "мыть", "чист", "гряз", "посуду", "стирк"},
CatPlumbing: {"кран", "труб", "сантехник", "вода", "слив", "унитаз", "раковин", "смесител"},
CatElectric: {"электрик", "розетк", "провод", "свет", "лампочк", "пробк", "автомат"},
CatDelivery: {"достав", "привез", "купить", "продукт", "аптек", "лекарств", "магазин"},
CatRepair:   {"ремонт", "мебел", "дверь", "окно", "стен", "полк", "повесить", "собрать"},
CatAssist:   {"сопровожд", "помоч", "дойти", "поликлиник", "больниц", "гулят", "поговорить"},
}

for cat, kws := range rules {
for _, k := range kws {
if strings.Contains(t, k) {
return cat, 2
}
}
}
return CatOther, 3
}
