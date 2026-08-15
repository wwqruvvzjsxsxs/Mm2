VisualTab:CreateSection("Оружие")

VisualTab:CreateToggle({
    Name = "🔫 Подсветка оружия",
    CurrentValue = _G.GunESP,
    Callback = function(Value)
        _G.GunESP = Value
        if Value then
            notify("🔫 ПОДСВЕТКА ОРУЖИЯ ВКЛЮЧЕНА", "Оружие подсвечивается сквозь стены", 3)
        else
            notify("🚫 ПОДСВЕТКА ОРУЖИЯ ВЫКЛЮЧЕНА", "Подсветка отключена", 3)
        end
    end,
})

VisualTab:CreateColorPicker({
    Name = "🎨 Цвет оружия",
    Color = _G.GunColor,
    Callback = function(Value)
        _G.GunColor = Value
    end,
})

VisualTab:CreateSection("Информация о ролях")
VisualTab:CreateLabel("🔴 Красный - Мардер")
VisualTab:CreateLabel("🔵 Синий - Шериф")
VisualTab:CreateLabel("🟢 Зеленый - Невинный (настраиваемый)")
VisualTab:CreateLabel("⚫ Черный - Оружие (настраиваемый)")

-- Заглушки для других вкладок
CombatTab:CreateSection("Боевые функции")
CombatTab:CreateLabel("Здесь будут боевые функции")

FarmTab:CreateSection("Фарм функции")
FarmTab:CreateLabel("Здесь будут функции фарма")

MiscTab:CreateSection("Прочие функции")
MiscTab:CreateLabel("Здесь будут прочие функции")

notify("✅ СКРИПТ ЗАГРУЖЕН!", "Базовая версия активирована!", 5)
