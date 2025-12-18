# СПО «Колибри» — ЛР6 (PostgreSQL + C++)

По методичке ЛР6 нужно: создать БД и таблицы в PostgreSQL, интегрировать БД в программу на C++, написать запросы, протестировать. fileciteturn2file0L1-L33

## 1) Создание таблиц
```bash
psql -U m4nuul -d kolibri_db -f sql/01_schema.sql
```

## 2) Сборка программы
### Ubuntu/Debian
```bash
sudo apt update
sudo apt install -y g++ cmake libpqxx-dev postgresql
mkdir -p build && cd build
cmake ..
cmake --build .
```

## 3) Запуск программы
По умолчанию подключение идёт через **unix-socket** (без host), чтобы не требовался пароль.

```bash
./kolibri
```

Если нужно подключение по TCP/паролю — задай переменные окружения:
```bash
export PGHOST=localhost
export PGPORT=5432
export PGDATABASE=kolibri_db
export PGUSER=m4nuul
export PGPASSWORD=1234
./kolibri
```

## 4) Функционал (меню в программе)
1. Добавление человека (+ документы/телефон/образование/профиль)
2. Поиск всех данных по ФИО
3. Поиск ФИО по телефону
4. Поиск ИНН по СНИЛС
5. Обновление телефона
6. Удаление человека
7. Показ последних N персон
8. Пример GROUP BY + COUNT
9. Пример HAVING

## 5) Запросы для отчёта
См. `sql/queries.sql` — набор разных запросов (JOIN, WHERE, GROUP BY, HAVING и т.п.). fileciteturn2file0L34-L63

## Подсказка про (END)
Если результат длинный и `psql` открывает просмотр (pager) и показывает `(END)`, выйти можно клавишей:
- `q` (quit)


# UML / ER-диаграмма БД СПО «Колибри» (вертикальная)

```mermaid
erDiagram
  PERSON ||--o{ PERSON_DOC : has
  PERSON ||--o{ PERSON_CONTACT : has
  PERSON ||--o{ EDUCATION : has
  PERSON ||--|| PERSON_PROFILE : has

  PERSON {
    BIGINT person_id PK
    TEXT last_name
    TEXT first_name
    TEXT middle_name "nullable"
    DATE birth_date "nullable"
    TIMESTAMPTZ created_at
  }

  PERSON_DOC {
    BIGINT doc_id PK
    BIGINT person_id FK
    DOC_TYPE doc_type "SNILS|INN|PASSPORT|OTHER"
    TEXT doc_number
    TIMESTAMPTZ created_at
  }

  PERSON_CONTACT {
    BIGINT contact_id PK
    BIGINT person_id FK
    CONTACT_TYPE contact_type "PHONE|EMAIL|OTHER"
    TEXT contact_value
    BOOLEAN is_primary
    TIMESTAMPTZ created_at
  }

  EDUCATION {
    BIGINT education_id PK
    BIGINT person_id FK
    TEXT organization "nullable"
    TEXT faculty "nullable"
    TIMESTAMPTZ created_at
  }

  PERSON_PROFILE {
    BIGINT person_id PK,FK
    TEXT citizenship "nullable"
    TEXT last_edu_doc "nullable"
    TEXT squad "nullable"
    TEXT prof_training "nullable"
    TEXT membership "nullable"
  }
