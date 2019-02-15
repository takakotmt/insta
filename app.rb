require 'sinatra'
require 'sinatra/reloader'
require 'mysql2'
require 'mysql2-cs-bind'
require 'pry'

enable :sessions
set :session_secret, 'super secret'
#mysqlの設定
client = Mysql2::Client.new(
    host: 'localhost',
    port: 3306,
    username: 'root',
    password: '',
    database: 'sample',
)

get '/index' do
  @articles = client.query("SELECT * FROM sample")#実行
  @name = session[:login_name]
  @comments = client.query("SELECT * FROM comments") #実行
  session[:post_id]=params['post_id']

  @comments_array = []
  @articles.each do |article|
    @comments_array[article['id']] = []

    res_comments = client.query("SELECT * FROM comments WHERE post_id = #{article['id']}")
    res_comments.each do |res_comment|
      @comments_array[article['id']].push({"comenter_name" => res_comment['creater_name'],"comment" => res_comment['content']})
    end
    # binding.pry
  end
# binding.pry
  erb :index
end
# 記事でeach してコメントでもeachする
# article　id と　commetのpost_id を比較して
# 一致するコメントを記事に詰める

#投稿ページ

post '/index' do
  @filename = params[:file][:filename]
  file = params[:file][:tempfile]
  File.open("./public/img/#{@filename}",'w') do |f|
    f.write(file.read)
  end

  sql = "INSERT INTO sample VALUES (NULL, '#{@filename}', DATE(NOW()), '#{params[:msg]}','#{session[:login_name]}');"
  client.query(sql)#保存

  redirect "/index"
end



#投稿表示ページ
get "/show" do
  @articles = client.query("SELECT * FROM sample")#実行

  erb :show
end



#ログインページ
get "/login" do
  @page_message = session[:page_message]
  session[:page_message] = nil

  erb :login
end

post '/login' do
    login= client.xquery("SELECT * FROM users where users_name = ? and users_pass = ?;", params[:login_name], params[:login_pass]).first

  if login
    session[:login_id] = login['id']
    session[:login_name] = login['users_name']
    session[:login_pass] = login['users_pass']
    redirect '/index'
  else
    session[:page_message] = "ログインできません"
    redirect '/login'
  end
end


#ログアウト
get '/logout' do
  session[:login] = nil
  redirect '/login'
end

#新規登録ページ
get "/signup" do
  @page_info = session[:page_info]
  session[:page_info] = nil
  erb :signup
end

post "/signup" do
  signup = client.xquery("SELECT * FROM users where users_name = ?;", params[:signup_name]).first

  if signup
    client.xquery("INSERT INTO users VALUES (NULL, ?, ?);", params[:signup_name], params[:signup_pass])
    session[:page_info] = "新規作成完了"
  else
    session[:page_info] = "既存アカウントです。"
  end

  redirect "/login"
end

#コメント機能
# get "/comment" do
#   @comment = client.query("SELECT * FROM comments") #実行
#   session[:post_id]=params['post_id'];
#
#   erb :comment
# end

post "/comment" do

  client.xquery('INSERT INTO comments (creater_id, creater_name, post_id, content) VALUES (?,?,?,?)', session[:login_id],session[:login_name],params[:post_id] ,params[:content])




  redirect "/index"
end

#投稿削除機能

delete "/file_delete" do
  FileUtils.rm_f("./public/img/#{@filename}")
  client.xquery("DELETE FROM sample WHERE id = ?;", params[:sample_id])

  redirect "/index"
end

#いいね機能
post "/iine" do
  client.xquery("INSERT INTO iines (user_id, post_id) VALUES (?,?)",session[:login_id],params[:post_id])

  redirect "/index"
end
