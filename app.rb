require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'

enable:sessions

get('/') do
  slim(:register)
end

get('/showlogin') do
  slim(:login)
end

post('/login') do
  username = params[:username]
  password = params[:password]
  db = SQLite3::Database.new('db/todolist.db')
  db.results_as_hash = true
  result = db.execute("SELECT * FROM users WHERE username = ?",username).first
  pwdigest = result["pwdigest"]
  id = result["id"]

  if BCrypt::Password.new(pwdigest) == password
    session[:id] = id
    redirect('/todos')
  else
    "Fel lösenord"
  end
end

get('/todos') do
  id = session[:id].to_i
  db = SQLite3::Database.new('db/todolist.db')
  db.results_as_hash = true
  result = db.execute("SELECT * FROM todos WHERE user_id = ?",id)
  p "Alla todos från result #{result}"
  slim(:"todos/index",locals:{todos:result})
end

post('/users/new') do
  username = params[:username]
  password = params[:password]
  password_confirm = params[:password_confirm]

  if (password == password_confirm)
    password_digest = BCrypt::Password.create(password)
    db = SQLite3::Database.new('db/todolist.db')
    db.execute("INSERT INTO users (username,pwdigest) VALUES (?,?)",username,password_digest)
    redirect('/')
  else 
    "Lösenorden matchade inte!"
  end

end

get('/todos') do
  db = SQLite3::Database.new("db/todolist.db")
  db.results_as_hash = true
  result = db.execute("SELECT * FROM todos")
  p result
  slim(:"todos/index",locals:{todos:result})
end

get('/todos/new') do
  slim(:"todos/new")
end

post('/todos/new') do
  title = params[:title]
  content = params[:content]
  user_id = session[:id]
  db = SQLite3::Database.new("db/todolist.db")
  db.execute("INSERT INTO todos (title, content, user_id) VALUES (?,?,?)",title, content, user_id)
  redirect('/todos')
end

post('/todos/:id/delete') do
  id = params[:id].to_i
  db = SQLite3::Database.new("db/todolist.db")
  db.execute("DELETE FROM todos WHERE id = ?",id)
  redirect('/todos')
end

post('/todos/:id/update') do
  id = params[:id].to_i
  title = params[:title]
  content = params[:content]
  db = SQLite3::Database.new("db/todolist.db")
  db.execute("UPDATE todos SET title=?,content=? WHERE user_id = ?",title,content,id)
  redirect('/todos')
end

get('/todos/:id/edit') do
  id = params[:id].to_i
  db = SQLite3::Database.new("db/todolist.db")
  db.results_as_hash = true
  result = db.execute("SELECT * FROM todos WHERE user_id = ?",id).first
  slim(:"/todos/edit",locals:{result:result})
end

get('/todos/:id') do
  id = params[:id].to_i
  db = SQLite3::Database.new("db/todolist.db")
  db.results_as_hash = true
  result = db.execute("SELECT * FROM todos WHERE user_id = ?",id).first
  result2 = db.execute("SELECT username FROM users WHERE id IN (SELECT id FROM todos WHERE user_id = ?)",id).first
  slim(:"todos/show",locals:{result:result,result2:result2})
end

