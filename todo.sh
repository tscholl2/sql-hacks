todo () {
  local file="$HOME/todo.db"
  local arg=$(echo $2 | xxd -p -u)
  local arg2=$(echo $3 | xxd -p -u)
  local sqlite="sqlite3 -line"
  if [[ ! -a $file ]]
  then
    sqlite3 $file "
CREATE TABLE IF NOT EXISTS items (
   id INTEGER PRIMARY KEY AUTOINCREMENT,
   text TEXT NOT NULL,
   start DATETIME NOT NULL DEFAULT (strftime('%s','now')),
   done DATETIME DEFAULT NULL,
   CHECK(text != '')
)
;"
  fi
  case $1 in
  "" | "list")
    $sqlite $file "
      SELECT
        id AS '#',
        text AS 'Item',
        DATETIME(start,'unixepoch','localtime') AS 'Assigned'
      FROM items
      WHERE done IS NULL
      ORDER BY start ASC
    ;"
    ;;
  "search" | "s")
    $sqlite $file "
      SELECT
        id AS '#',
        text AS 'Item',
        DATETIME(start,'unixepoch','localtime') AS 'Assigned',
        DATETIME(done,'unixepoch','localtime') AS 'Finished'
      FROM items
      WHERE text LIKE '%'||trim(x'$arg',x'200A0D0B')||'%'
      ORDER BY done ASC,start ASC
    ;"
  ;;
  "add" | "a" )
    $sqlite $file "
      INSERT INTO items (text) VALUES (
        trim(coalesce(
          nullif(trim(x'$arg',x'200A0D0B'),''),
          edit('','$EDITOR')
        ),x'200A0D0B')
      )
    ;"
    ;;
  "edit" | "e")
    $sqlite $file "
      UPDATE items SET text=trim(coalesce(
        nullif(trim(x'$arg2',x'200A0D0B'),''),
        edit(text,'$EDITOR')
      ),x'200A0D0B')
      WHERE id=CAST(x'$arg' AS INTEGER)
    ;"
    ;;
  "complete" | "c")
    $sqlite $file "
      UPDATE items SET done=strftime('%s','now')
      WHERE id=CAST(x'$arg' AS INTEGER)
    ;"
    ;;
  *)
    echo "todo based on sqlite

  EXAMPLES:

  todo
  todo list
  todo add 'something'
  todo search 'ktty'
  todo complete 2
  todo edit 3
  todo help
"
  esac
}