# example.nim
import sugar, strutils, sequtils, strformat
import htmlgen
import jester
import db_sqlite



type Todo* = object
  id: int
  content: string
  done: bool


include "views.nimf"

proc selectTodo(row: seq[string]): Todo =
  return Todo(id: row[0].parseInt, content: row[1], done: row[2].parseBool)


proc parseHtmlBool(b: string): bool =
  b == "on"

# user, password, database name can be empty.
# These params are not used on db_sqlite module.
let db = open("mytest.db", "", "", "")
#[
db.exec(sql"DROP TABLE IF EXISTS todos")
db.exec(sql"""CREATE TABLE todos (
                 id   INTEGER PRIMARY KEY,
                 content VARCHAR(50) NOT NULL,
                 done BOOLEAN NOT NULL default 0
              )""")
db.exec(sql"INSERT INTO todos (content) VALUES (?) ", "niquer des mères")
db.exec(sql"INSERT INTO todos (content) VALUES (?) ", "niquer des pères")
db.exec(sql"INSERT INTO todos (content) VALUES (?) ", "leur fêter leur fête")
]#

routes:
  get "/":
    var answer: seq[string] = @[]
    answer.add "<!DOCTYPE html> <html><body>"
    answer.add "  <script src=\"https://unpkg.com/htmx.org@1.1.0\"></script>"
    answer.add """
    <link rel="stylesheet" href="https://unpkg.com/spectre.css/dist/spectre.min.css">
    <link rel="stylesheet" href="https://unpkg.com/spectre.css/dist/spectre-exp.min.css">
    <link rel="stylesheet" href="https://unpkg.com/spectre.css/dist/spectre-icons.min.css">
"""
    var todos = collect(newSeq):
      for x in db.fastRows(sql"SELECT * FROM todos"):
        selectTodo(x)


    answer.add genPage(todos)
    answer.add "</body></html>"
    resp answer.join()



  get "/edit/@todoid?":
    echo @"todoid"

    var answer: seq[string] = @[]
    answer.add "<!DOCTYPE html> <html><body>"
    if @"todoid" == "":
      answer.add genEditForm(-1, "", false)
    else:
      let value = db.getRow(sql"SELECT * FROM todos WHERE id = ?", @"todoid")
      answer.add genEditForm(value[0].parseInt, value[1], value[2].parseBool)
    answer.add "</body></html>"

    resp answer.join ""

  delete "/delete/@todoid":
    discard db.getRow(sql"DELETE FROM todos WHERE id = ?", @"todoid")
    resp ""

  post "/edit/@todoid?":
    dump @"todoid"
    dump @"content"
    dump @"done"
    if @"todoid".parseInt == -1:
      let id = db.insertID(sql"INSERT INTO todos (content, done) VALUES (?, ?)",
        @"content", parseHtmlBool(@"done"))
    else:
      let id = db.insertID(sql"UPDATE todos SET (content, done) = (?, ?) WHERE id= ?",
          @"content", parseHtmlBool(@"done"), @"todoid")
    redirect "/"





db.close()
