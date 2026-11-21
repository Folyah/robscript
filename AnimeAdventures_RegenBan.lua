-- Folyah: RobScript original completo + unica regra: Regen proibido na Dungeon.
-- Nao modifica Shielding, lojas, farms, posicionamento ou Summer Hunt.
-- Recusa Regen na sala atual e em caminhos que forcam Regen na proxima sala visivel.
-- Fonte original armazenada no proprio repositorio: Folyah/robscript.
local url = "https://raw.githubusercontent.com/Folyah/robscript/main/AnimeAdventures"
local source = game:HttpGet(url)
assert(type(source) == "string" and #source > 100000, "RobScript completo nao encontrado")

local function replaceExactlyOnce(before, after, label)
    local a, b = source:find(before, 1, true)
    assert(a, "RobScript: trecho nao encontrado: " .. label)
    assert(not source:find(before, b + 1, true), "RobScript: trecho duplicado: " .. label)
    source = source:sub(1, a - 1) .. after .. source:sub(b + 1)
end

replaceExactlyOnce([===[function Dungeon.curseOk(sxb, txb, uxb, vxb, wxb)
]===], [===[function Dungeon.isRegenCurse(id)
    return Dungeon.isCurse(id) and tostring(id):lower():find("regen", 1, true) ~= nil
end

function Dungeon.curseOk(sxb, txb, uxb, vxb, wxb)
    if Dungeon.isRegenCurse(sxb) then
        return false, "Regen is forbidden in Dungeon"
    end
]===], "patch 1")

-- Olha a proxima camada de salas que o jogo ja tornou visivel.
-- Ignora Regen na pontuacao das recompensas futuras e evita becos sem saida.
replaceExactlyOnce([===[        local hyb, iyb
        for jyb, kyb in ipairs(Dungeon.after(Uxb, fyb.choice)) do
            local lyb = Dungeon.roomValue(kyb, Xxb)
            if not hyb or lyb > hyb then
                hyb, iyb = lyb, kyb
            end
        end
]===], [===[        local hyb, iyb
        local futureRooms = Dungeon.after(Uxb, fyb.choice)
        local futureSafe = 0
        for jyb, kyb in ipairs(futureRooms) do
            if not Dungeon.isRegenCurse(Dungeon.roomCurse(kyb.r)) then
                futureSafe = futureSafe + 1
                local lyb = Dungeon.roomValue(kyb, Xxb)
                if not hyb or lyb > hyb then
                    hyb, iyb = lyb, kyb
                end
            end
        end
        local futureRegenTrap = #futureRooms > 0 and futureSafe == 0
]===], "patch 2: reject visible future Regen in route planning")

replaceExactlyOnce([===[        local qyb, ryb, syb = pcall(Dungeon.curseGate, fyb, Uxb)
        if qyb and not ryb then
            fyb.blocked = syb
        end
]===], [===[        local qyb, ryb, syb = pcall(Dungeon.curseGate, fyb, Uxb)
        if Dungeon.isRegenCurse(Dungeon.roomCurse(fyb.r)) then
            fyb.blocked = "Regen is forbidden in Dungeon"
        elseif futureRegenTrap then
            fyb.blocked = "all visible next rooms require Regen"
        elseif qyb and not ryb then
            fyb.blocked = syb
        end
]===], "patch 3: block Regen now and unavoidable next-room Regen")

replaceExactlyOnce([===[        if not dyb or fyb.score > dyb.score then
            dyb = fyb
        end
]===], [===[        if not Dungeon.isRegenCurse(Dungeon.roomCurse(fyb.r)) and not futureRegenTrap
            and (not dyb or fyb.score > dyb.score) then
            dyb = fyb
        end
]===], "patch 4: protect fallback from Regen traps")

replaceExactlyOnce([===[    if not iCb then
        Dungeon.logState(cCb, "no rooms on offer")
]===], [===[    if not iCb then
        local allRooms = Dungeon.rooms(cCb)
        local regenUnavoidable = #allRooms > 0
        for _, room in ipairs(allRooms) do
            local nextRooms = Dungeon.after(cCb, room.choice)
            local futureTrap = #nextRooms > 0
            for _, nextRoom in ipairs(nextRooms) do
                if not Dungeon.isRegenCurse(Dungeon.roomCurse(nextRoom.r)) then
                    futureTrap = false
                    break
                end
            end
            if not Dungeon.isRegenCurse(Dungeon.roomCurse(room.r)) and not futureTrap then
                regenUnavoidable = false
                break
            end
        end
        if regenUnavoidable then
            Dungeon.note("every visible route requires Regen now or in the next room; returning to lobby")
            App.saveNow()
            App.request("lobby", "teleport_back_to_lobby")
            return false
        end
        Dungeon.logState(cCb, "no rooms on offer")
]===], "patch 5: leave if all visible routes force Regen")

-- Garante que um Shrine com Regen seja recusado mesmo se a simulacao falhar.
replaceExactlyOnce([===[            if Ozb and not Pzb then
                Kzb = Qzb
            end
]===], [===[            if Dungeon.isRegenCurse(Mzb.id) or (Ozb and not Pzb) then
                Kzb = Dungeon.isRegenCurse(Mzb.id) and "Regen is forbidden in Dungeon" or Qzb
            end
]===], "patch 6: Shrine Regen hard ban")

-- Interface preservada no fork de Folyah/Robly_Airflow.
-- Faça o fork antes de executar este loader, para que a biblioteca seja encontrada.
replaceExactlyOnce([===[Core.AIRFLOW_URL = "https://raw.githubusercontent.com/bobloscript/Robly_Airflow/main/Source.luau"]===], [===[Core.AIRFLOW_URL = "https://raw.githubusercontent.com/Folyah/Robly_Airflow/main/Source.luau"]===], "interface Robly Airflow propria")

-- Se o codigo original mudar, a validacao interrompe a execucao em vez de
-- carregar silenciosamente um script sem o banimento de Regen.
local run, err = loadstring(source, "=Folyah_AnimeAdventures_RegenBan")
assert(run, err)
return run()
