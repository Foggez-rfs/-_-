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

func ClassifyOrder(text string) (Category, int) {
	text = strings.ToLower(text)

	urgent := []string{"срочно", "авария", "затопило", "прорвало", "пожар"}
	for _, kw := range urgent {
		if strings.Contains(text, kw) {
			return CatPlumbing, 1
		}
	}

	rules := map[Category][]string{
		CatCleaning: {"убор", "пылесос", "мыть", "чист", "гряз"},
		CatPlumbing: {"кран", "труб", "сантехник", "вода", "слив", "унитаз"},
		CatElectric: {"электрик", "розетк", "провод", "свет", "лампочк"},
		CatDelivery: {"достав", "привез", "купить", "продукт", "аптек", "лекарств"},
		CatRepair:   {"ремонт", "мебел", "дверь", "окно", "стен", "полк"},
		CatAssist:   {"сопровожд", "помоч", "дойти", "поликлиник", "больниц"},
	}
	for cat, keywords := range rules {
		for _, kw := range keywords {
			if strings.Contains(text, kw) {
				return cat, 2
			}
		}
	}
	return CatOther, 3
}
