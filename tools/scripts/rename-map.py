#!/usr/bin/env python3
"""One-off: rename audiobook folders to 'Author - Title' latin-only naming.

Usage: rename-map.py <library_root>
"""
import sys
from pathlib import Path

MAPPING = {
    "King_S_ChS_01_Rita_Heyuort_ili_Pobeg_iz_Shoushenka_(Knyazev_I)": "Stephen King - Rita Heyuort ili Pobeg iz Shoushenka",
    "King_S_TBH_02_Kto_nashel_beret_sebe_(Knyazev_I)": "Stephen King - Kto Nashel Beret Sebe",
    "King_S_TBH_03_Post_sdal_(Knyazev_I)": "Stephen King - Post Sdal",
    "King_Stephen_-_Mr._Mercedes_(Knyazev_Igor)": "Stephen King - Mr.Mercedes",
    "Stephen King - Mr. Mercedes (Сергій Москаленко) - 2023 (213-243kbps)": "Stephen King - Mr. Mercedes (Ukrainian)",
    "T.Lebbon.KhizhinaVlesu.2020.Vladimir.Kniazev.MP3.192kbps": "Tim Lebbon - Khizhina v Lesu",
    "Аарон Дембски-Боуден - Ловец Душ + Рыцарь Теней (Кирилл Головин)": "Aaron Dembski-Bowden - Lovets Dush + Rytsar Teney",
    "Аарон Дембски-Боуден - Первый Еретик": "Aaron Dembski-Bowden - Pervyi Yeretik",
    "Аарон Дембски-Боуден - Черный Легион (Casper Valter)": "Aaron Dembski-Bowden - Chernyi Legion",
    "Андрей Солдатов, Ирина Бороган - Свои среди чужих (чит. Вадим Чернобельский)": "Andrey Soldatov, Irina Borogan - Svoy Sredi Chuzich",
    "Баданин Роман, Рубин Михаил - Царь собственной персоной [Артур Смольянинов]": "Roman Badanin, Michaeil Rubin - Tsar Sobstvennoy Personoy",
    "Бентли Литтл - Консультант [Игорь Князев]": "Bentley Little - Konsultant",
    "Берен и Лутиэн": "J.R.R. Tolkien - Beren and Luthien",
    "Брукс Майк - Warhammer 40000. Альфарий. Голова Гидры (Casper Valter)": "Mike Brooks - Alfarius. Golova Gidry",
    "Будда, мозг и нейрофизиология счастья": "Buddha, Mozg i Neyrofiziologiya Schastya",
    "Виктор Пелевин - Возвращение Синей Бороды [Ксения Собчак, Кирилл Радциг, Митя Лебедев]": "Victor Pelevin - Vozvrashcheniye Siney Borody",
    "Водолазкин Евгений - Лавр [Сергей Вензелев]": "Evgeny Vodolazkin - Lavr",
    "Гай Хейли - Конрад Курц. Ночной Призрак (Casper Valter)": "Guy Haley - Konrad Kurtz. Nochnoy Prizrak",
    "Гессе Герман - Сиддхартха ( Савицкий Николай )": "Hermann Hesse - Siddhartha",
    "Дж.Р.Р.Толкин - Дети Хурина (Сергей Бунтман)": "J.R.R. Tolkien - Deti Khurina",
    "Дэн Симмонс_Друд, или Человек в черном_Игорь Князев": "Dan Simmons - Drood, ili Chelovek v Chernom",
    "Захаров Андрей - Крипта [Захаров Андрей]": "Andrey Zakharov - Kripta",
    "Зыгарь Михаил - Вся кремлевская рать (Борис Блохин) - 2016": "Mikhail Zygar - Vsya Kremlevskaya Rat",
    "Зыгарь Михаил - Империя должна умереть Часть 1 (Владимир Левашев)": "Mikhail Zygar - Imperiya Dolzhna Umeret Chast 1",
    "Зыгарь Михаил - Империя должна умереть Часть 2 (Владимир Левашев)": "Mikhail Zygar - Imperiya Dolzhna Umeret Chast 2",
    "Иван Ефремов -  Лезвие бритвы [Александр Бордуков]": "Ivan Yefremov - Lezviye Britvy",
    "Йенер Харальд - Волчье время [Таня Фельгенгауэр]": "Harald Jähner - Volchye Vremya",
    "Кинг Стивен – Будет кровь [Игорь Князев]": "Stephen King - Budet Krov",
    "Кинг Стивен – Чужак [Игорь Князев]": "Stephen King - Chuzhak",
    "Климан Дженни - Секс без людей, мясо без животных [Татьяна Фельгенгауэр]": "Jenny Kleeman - Seks Bez Lyudey, Myaso Bez Zhivotnykh",
    "Маккаммон Роберт – Пятёрка [Олег Булдаков]": "Robert McCammon - Pyaterka",
    "Мингьюр Ринпоче - Превращая заблуждение в ясность": "Yongey Mingyur Rinpoche - Prevrashchaya Zabluzhdeniye v Yasnost",
    "Михаил Зыгарь - Все свободны (Артем Пахомов)": "Mikhail Zygar - Vse Svobodny",
    "Никита Смагин - Всем Иран. Парадоксы жизни в автократии под санкциями [Никита Смагин]": "Nikita Smagin - Vsem Iran",
    "Оно (2019)": "Stephen King - Ono",
    "Оруэлл Джордж - 1984 (Чит.Сергей Чонишвили)": "George Orwell - 1984",
    "Пелевин Виктор - Чапаев и Пустота [Черняк Михаил]": "Victor Pelevin - Chapaev i Pustota",
    "Радостная мудрость 256": "Radostnaya Mudrost",
    "Саша Филипенко - Слон [Григорий Перель]": "Sasha Filipenko - Slon",
    "Соловьев Леонид - Возмутитель спокойствия [Герасимов Вячеслав]": "Leonid Solovyov - Vozmutitel Spokoystviya",
    "Соловьев Леонид - Очарованный принц [Герасимов Вячеслав]": "Leonid Solovyov - Ocharovanny Prints",
    "Стивен Кинг — Билли Саммерс [исп. Игорь Князев]": "Stephen King - Billy Summers (RU)",
    "Стивен Кинг - Возрождение (Игорь Князев)": "Stephen King - Vozrozhdeniye",
    "Стивен Кинг - Сказка. 2024 Олег Булдаков": "Stephen King - Skazka",
    "Стивен Кинг - Темная Башня 0-7 (Роман Волков и др.)": "Stephen King - Temnaya Bashnya 0-7",
    "Стругацкие А. и Б. - Полдень, XXII век (Владимир Левашев)": "Arkady and Boris Strugatsky - Polden XXII Vek",
    "Стругацкие Аркадий и Борис - Гадкие лебеди [Владимир Левашев]": "Arkady and Boris Strugatsky - Gadkiye Lebedi",
    "Стругацкие - Улитка на склоне [Левашёв]": "Arkady and Boris Strugatsky - Ulitka na Sklone",
    "Толкин Джон - Сильмариллион [Женёк (ЛИ)]": "J.R.R. Tolkien - Silmarillion",
    "Торп Гэв - Лоргар. Носитель Слова (Casper Valter)": "Gav Thorpe - Lorgar. Nositel Slova",
    "Филип Дик - Стигматы Палмера Элдрича [Александр Слуцкий]": "Philip K. Dick - Stigmaty Palmera Eldricha",
    "Филип Дик - Убик [Александр Кузнецов]": "Philip K. Dick - Ubik",
    "Хейли Гай - Генный отец [Casper Valter]": "Guy Haley - Genny Otets",
    "Хью Хауи - Укрытие. Книга 1. Иллюзия [Станислав Федорчук]": "Hugh Howey - Ukrytiye. Kniga 1. Illyuziya",
    "Хью Хауи - Укрытие. Книга 2. Смена [Станислав Федорчук]": "Hugh Howey - Ukrytiye. Kniga 2. Smena",
    "Хью Хауи - Укрытие. Книга 3. Пыль [Станислав Федорчук]": "Hugh Howey - Ukrytiye. Kniga 3. Pyl",
    "Шантидева - Вступая на путь Бодхисаттвы (Бодхичарья-аватара)": "Shantideva - Vstupaya na Put Bodkhisattvy",
}

def main():
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(1)
    root = Path(sys.argv[1])

    renamed, missing, collisions = [], [], []
    for old, new in MAPPING.items():
        src = root / old
        dst = root / new
        if not src.exists():
            missing.append(old)
            continue
        if dst.exists():
            collisions.append(f"{old} -> {new} (target already exists)")
            continue
        src.rename(dst)
        renamed.append(f"{old} -> {new}")

    print(f"=== RENAMED ({len(renamed)}) ===")
    for line in renamed:
        print(line)
    if missing:
        print(f"\n=== MISSING SOURCE ({len(missing)}) ===")
        for line in missing:
            print(line)
    if collisions:
        print(f"\n=== COLLISIONS ({len(collisions)}) ===")
        for line in collisions:
            print(line)

if __name__ == "__main__":
    main()
