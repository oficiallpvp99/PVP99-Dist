PVP99 - BOOK WORLD / INSTALADOR OTCv8

PACOTE ANALISADO
- Arquivos originais: 107
- Pastas originais: 17
- Destino no OTCv8: /bot/Book-World

COMO SUBIR NO GITHUB
1. Abra o repositorio publico PVP99-Dist.
2. Envie a pasta Book-World inteira deste pacote.
3. Confirme que estes dois arquivos existem:
   Book-World/installer.lua
   Book-World/manifest.lua
4. Depois, no OTCv8, execute o codigo abaixo:

HTTP.get("https://raw.githubusercontent.com/oficiallpvp99/PVP99-Dist/refs/heads/main/Book-World/installer.lua", function(script, err)
  if err then
    print("[PVP99] Erro: " .. tostring(err))
    return
  end

  local fn, loadErr = loadstring(script)
  if not fn then
    print("[PVP99] Erro no installer: " .. tostring(loadErr))
    return
  end

  fn()
end)


O installer cria as pastas e baixa todos os arquivos um por um.
Ao terminar, ele atualiza a lista de Bots do OTCv8.

IMPORTANTE
- Os arquivos .lua deste pacote ainda sao os originais do ZIP enviado.
- Antes da distribuicao final, podemos ligar este pacote ao pipeline de ofuscacao.
