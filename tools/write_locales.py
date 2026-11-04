"""Authoring source for the seven UTF-8 ESO localization files."""
from pathlib import Path
import json

KEYS = """SETTINGS INCOMING OUTGOING GUILD OFFICER OTHER CHECK_HINT EXPAND_HINT EMPTY_CHANNEL NO_CHANNELS SELECT_CHANNEL FORMATTING TIMESTAMPS TIMESTAMPS_HINT NEWLINE NEWLINE_HINT ABBREVIATIONS ABBREVIATIONS_HINT HOME_BUTTON HOME_TOOLTIP NO_HOME TRAVEL_UNAVAILABLE ACTION_UNAVAILABLE COPY COPY_HINT COPY_EXPIRED COPY_MULTIPLE NEWER_SCHEMA""".split()
TRANSLATIONS = {
"en": [
"OneChat settings", "Incoming", "Outgoing", "Guild", "Officer", "Other",
"Enable or disable all channels in this row. A dash means some channels are selected.",
"Expand or collapse without changing the channel selection.", "—", "No available outgoing channels",
"Select an outgoing channel or enter a channel command before sending.",
"Chat", "Show timestamps", "Show the local time before new player messages.",
"Message text on a new line", "Start the message on the line below the sender.",
"Guild abbreviations", "Leave blank to use the full guild name. Changes apply to new messages.",
"Show primary residence button", "Travel to your primary residence", "No primary residence is set.",
"Travel is unavailable. The player must be an accessible group member, friend, or guild member.",
"This action is currently unavailable.", "Copy", "Press Ctrl+C to copy the selected text.",
"This message is no longer in OneChat's copy history.",
"This link appears in <<1>> stored messages. Select the text you want to copy below.",
"These settings were saved by a newer OneChat version. Update OneChat to use them safely.",
],
"de": [
"OneChat-Einstellungen", "Eingehend", "Ausgehend", "Gilde", "Offiziere", "Sonstige",
"Alle Kanäle dieser Zeile aktivieren oder deaktivieren. Ein Strich zeigt eine Teilauswahl an.",
"Ein- oder ausklappen, ohne die Kanalauswahl zu ändern.", "—", "Keine ausgehenden Kanäle verfügbar",
"Wählt vor dem Senden einen ausgehenden Kanal oder gebt einen Kanalbefehl ein.",
"Chat-Einstellungen", "Zeitstempel anzeigen", "Die Ortszeit vor neuen Spielernachrichten anzeigen.",
"Nachricht in neuer Zeile", "Den Nachrichtentext unter dem Absender beginnen.",
"Gildenkürzel", "Leer lassen, um den vollen Gildennamen zu verwenden. Gilt für neue Nachrichten.",
"Hauptwohnsitz-Schaltfläche anzeigen", "Zum Hauptwohnsitz reisen", "Es ist kein Hauptwohnsitz festgelegt.",
"Reisen ist nicht möglich. Das Ziel muss ein erreichbares Gruppenmitglied, ein Freund oder ein Gildenmitglied sein.",
"Diese Aktion ist derzeit nicht verfügbar.", "Kopieren", "Drückt Strg+C, um den markierten Text zu kopieren.",
"Diese Nachricht ist nicht mehr im Kopierverlauf von OneChat.",
"Dieser Link kommt in <<1>> gespeicherten Nachrichten vor. Markiert unten den gewünschten Text.",
"Diese Einstellungen stammen von einer neueren OneChat-Version. Aktualisiert OneChat, um sie sicher zu verwenden.",
],
"fr": [
"Paramètres de OneChat", "Réception", "Envoi", "Guilde", "Officiers", "Autres",
"Activer ou désactiver tous les canaux de cette ligne. Un tiret indique une sélection partielle.",
"Développer ou réduire sans modifier les canaux sélectionnés.", "—", "Aucun canal d’envoi disponible",
"Sélectionnez un canal d’envoi ou saisissez une commande de canal avant d’envoyer un message.",
"Discussion", "Afficher l’heure", "Afficher l’heure locale avant les nouveaux messages des joueurs.",
"Message sur une nouvelle ligne", "Afficher le texte du message sous le nom de l’expéditeur.",
"Abréviations des guildes", "Laissez vide pour afficher le nom complet. S’applique aux nouveaux messages.",
"Afficher le bouton de résidence principale", "Voyager vers votre résidence principale", "Aucune résidence principale n’est définie.",
"Voyage indisponible. La cible doit être un membre du groupe, un ami ou un membre de guilde accessible.",
"Cette action est actuellement indisponible.", "Copier", "Appuyez sur Ctrl+C pour copier le texte sélectionné.",
"Ce message ne figure plus dans l’historique de copie de OneChat.",
"Ce lien apparaît dans <<1>> messages enregistrés. Sélectionnez le texte à copier ci-dessous.",
"Ces paramètres proviennent d’une version plus récente de OneChat. Mettez OneChat à jour pour les utiliser sans risque.",
],
"ru": [
"Настройки OneChat", "Входящие", "Исходящие", "Гильдия", "Офицеры", "Прочее",
"Включить или отключить все каналы в этой строке. Черта означает, что выбрана часть каналов.",
"Развернуть или свернуть список, не меняя выбранные каналы.", "—", "Нет доступных исходящих каналов",
"Перед отправкой выберите исходящий канал или введите команду канала.",
"Чат", "Показывать время", "Показывать местное время перед новыми сообщениями игроков.",
"Текст сообщения с новой строки", "Показывать текст сообщения под именем отправителя.",
"Аббревиатуры", "Оставьте поле пустым для полного названия. Применяется к новым сообщениям.",
"Показывать кнопку основного дома", "Переместиться в основной дом", "Основной дом не выбран.",
"Перемещение недоступно. Игрок должен быть доступным участником группы, другом или согильдийцем.",
"Сейчас это действие недоступно.", "Копировать", "Нажмите Ctrl+C, чтобы скопировать выделенный текст.",
"Этого сообщения больше нет в истории копирования OneChat.",
"Эта ссылка встречается в сохранённых сообщениях: <<1>>. Выделите нужный текст ниже.",
"Настройки сохранены более новой версией OneChat. Обновите аддон для безопасной работы с ними.",
],
"es": [
"Ajustes de OneChat", "Entrantes", "Salientes", "Gremio", "Oficiales", "Otros",
"Activar o desactivar todos los canales de esta fila. Una raya indica una selección parcial.",
"Desplegar o contraer sin cambiar los canales seleccionados.", "—", "No hay canales de salida disponibles",
"Selecciona un canal de salida o introduce un comando de canal antes de enviar.",
"Conversación", "Mostrar la hora", "Mostrar la hora local antes de los nuevos mensajes de jugadores.",
"Mensaje en una línea nueva", "Mostrar el texto del mensaje debajo del remitente.",
"Abreviaturas de gremios", "Deja el campo vacío para usar el nombre completo. Se aplica a mensajes nuevos.",
"Mostrar botón de residencia principal", "Viajar a tu residencia principal", "No has establecido una residencia principal.",
"No se puede viajar. El jugador debe ser un miembro del grupo, un amigo o un compañero de gremio accesible.",
"Esta acción no está disponible en este momento.", "Copiar", "Pulsa Ctrl+C para copiar el texto seleccionado.",
"Este mensaje ya no está en el historial de copia de OneChat.",
"Este enlace aparece en <<1>> mensajes guardados. Selecciona abajo el texto que quieras copiar.",
"Estos ajustes se guardaron con una versión más reciente de OneChat. Actualiza OneChat para usarlos de forma segura.",
],
"zh": [
"OneChat设置", "接收频道", "发送频道", "公会", "官员", "其他",
"启用或禁用本行的所有频道。横线表示仅选择了部分频道。",
"展开或折叠列表，不会更改频道选择。", "—", "没有可用的发送频道",
"发送前请选择一个发送频道，或输入频道命令。",
"聊天", "显示时间", "在新的玩家消息前显示本地时间。",
"消息正文另起一行", "在发送者名称下方显示消息正文。",
"公会简称", "留空则显示公会全名。更改仅对新消息生效。",
"显示主要住所按钮", "传送至你的主要住所", "尚未设置主要住所。",
"无法传送。目标玩家必须是可以传送的队伍成员、好友或公会成员。",
"当前无法执行此操作。", "复制", "按Ctrl+C复制选中的文本。",
"此消息已不在OneChat的复制历史中。",
"有<<1>>条已保存的消息包含此链接。请在下方选择要复制的文本。",
"这些设置由较新版本的OneChat保存。请先更新OneChat，以便安全使用这些设置。",
],
"jp": [
"OneChat設定", "受信チャンネル", "送信チャンネル", "ギルド", "オフィサー", "その他",
"この行の全チャンネルを有効または無効にします。横線は一部のみ選択されていることを示します。",
"チャンネルの選択を変えずにリストを展開・折りたたみます。", "—", "利用できる送信チャンネルがありません",
"送信チャンネルを選択するか、チャンネルコマンドを入力してから送信してください。",
"チャット", "時刻を表示", "新しいプレイヤーメッセージの前に現地時刻を表示します。",
"本文を次の行に表示", "送信者名の下の行にメッセージ本文を表示します。",
"ギルド名の略称", "空欄の場合は正式名を表示します。変更は新しいメッセージに適用されます。",
"主邸ボタンを表示", "自分の主邸に移動", "主邸が設定されていません。",
"移動できません。移動先は、移動可能なグループメンバー、フレンド、またはギルドメンバーである必要があります。",
"現在この操作はできません。", "コピー", "Ctrl+Cで選択したテキストをコピーできます。",
"このメッセージはOneChatのコピー履歴に残っていません。",
"このリンクを含む保存済みメッセージが<<1>>件あります。下からコピーするテキストを選択してください。",
"この設定は新しいバージョンのOneChatで保存されています。安全に使用するにはOneChatを更新してください。",
],
}

KEYS += ["RELOAD_BUTTON", "RELOAD_TOOLTIP", "LANGUAGE_BUTTON", "LANGUAGE_TOOLTIP"]
EXTRA = {
"en": ["Show reload UI button", "Reload the user interface", "Show game language button", "Change game language (reloads the interface)"],
"de": ["Schaltfläche zum Neuladen anzeigen", "Benutzeroberfläche neu laden", "Sprachauswahl anzeigen", "Spielsprache ändern (lädt die Oberfläche neu)"],
"fr": ["Afficher le bouton de rechargement", "Recharger l’interface", "Afficher le bouton de langue", "Changer la langue du jeu (recharge l’interface)"],
"ru": ["Показывать кнопку перезагрузки", "Перезагрузить интерфейс", "Показывать кнопку выбора языка", "Сменить язык игры (интерфейс перезагрузится)"],
"es": ["Mostrar botón de recarga", "Recargar la interfaz", "Mostrar botón de idioma", "Cambiar el idioma del juego (recarga la interfaz)"],
"zh": ["显示界面重载按钮", "重新加载界面", "显示游戏语言按钮", "更改游戏语言（将重新加载界面）"],
"jp": ["UI再読み込みボタンを表示", "インターフェースを再読み込み", "言語選択ボタンを表示", "ゲームの言語を変更（UIが再読み込みされます）"],
}
for code, values in EXTRA.items():
    TRANSLATIONS[code] += values

KEYS.append("BUTTONS_SECTION")
for code, text in {"en": "Buttons", "de": "Schaltflächen", "fr": "Boutons", "ru": "Кнопки", "es": "Botones", "zh": "按钮", "jp": "ボタン"}.items():
    TRANSLATIONS[code].append(text)

if __name__ == "__main__":
    root = Path(__file__).resolve().parents[1] / "OneChat" / "lang"
    root.mkdir(parents=True, exist_ok=True)
    for language, values in TRANSLATIONS.items():
        assert len(values) == len(KEYS), (language, len(values), len(KEYS))
        lines = ["-- UTF-8. English base strings are loaded before the active language.", "local strings = {"]
        lines += [f'    SI_ONECHAT_{key} = {json.dumps(value, ensure_ascii=False)},' for key, value in zip(KEYS, values)]
        lines += ["}", "for id, text in pairs(strings) do"]
        if language == "en":
            lines += ["    if not _G[id] then ZO_CreateStringId(id, text) end"]
        else:
            lines += ["    SafeAddString(_G[id], text, 1)"]
        lines += ["end", ""]
        (root / f"{language}.lua").write_text("\n".join(lines), encoding="utf-8")
