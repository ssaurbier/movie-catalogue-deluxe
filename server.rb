require 'sinatra'
require 'shotgun'
require 'pg'

def db_connection
  begin
    connection = PG.connect(dbname: "movies")
    yield(connection)
  ensure
    connection.close
  end
end

get "/actors" do
  actors = db_connection { |conn| conn.exec("SELECT actors.name FROM actors ORDER BY actors.name") }
  erb :'actors/index', locals: { actors: actors }
end



get "/actors/:actor_name" do
  actor_name = params[:actor_name]
    db_connection do |conn|
    details = conn.exec_params('
      SELECT movies.title, movies.year, cast_members.character
      FROM actors
      JOIN cast_members
      ON actors.id = cast_members.actor_id
      JOIN movies
      ON movies.id = cast_members.movie_id
      WHERE actors.name = ($1)  ORDER BY year', [params[:actor_name]])
    erb :'actors/show', locals: { actor_name: params[:actor_name], details: details }
  end
end


get "/" do
  erb :'movies/show'
end

get "/movies" do
  movies = db_connection { |x| x.exec("SELECT movies.title, movies.year, movies.rating, genres.name AS genre, studios.name AS studio
  FROM movies
  JOIN genres ON movies.genre_id = genres.id
  LEFT OUTER JOIN studios on movies.studio_id = studios.id
  ORDER BY movies.title;") }
  erb :'movies/index', locals: { movies: movies}
end


get "/movies/:id" do
  film = db_connection { |conn| conn.exec("
  SELECT genres.name as genres, studios.name as studio,
    actors.name as actor, cast_members.character as character
  FROM cast_members
  JOIN movies ON cast_members.movie_id = movies.id
  JOIN actors ON cast_members.actor_id = actors.id
  JOIN genres ON movies.genre_id = genres.id
  JOIN studios ON movies.studio_id = studios.id
  WHERE movies.title = '#{params[:id]}';")}
  erb :'movies/show', locals: { id: params[:id], film: film}
end


# get '/movies/:movie_name' do
#   movie_name = params[:movie_name]
#   db_connection do |conn|
#     movie_details = conn.exec('
#     SELECT actors.name "actor", cast_members.character, genres.name "genre", studios.name "studio"
#     FROM movies
#     JOIN cast_members
#     ON cast_members.movie_id = movies.id
#     JOIN actors
#     ON actors.id = cast_members.actor_id
#     JOIN studios
#     ON movies.studio_id = studios.id
#     JOIN genres
#     ON movies.genre_id = genres.id
#     WHERE movies.title = ($1)', [params[:movie_name]])
#
#     genre_studio = conn.exec('
#     SELECT genres.name "genre", studios.name "studio"
#     FROM movies
#     JOIN studios
#     ON movies.studio_id = studios.id
#     JOIN genres
#     ON movies.genre_id = genres.id
#     WHERE movies.title = ($1)', [params[:movie_name]])
#
#     erb :'movies/show', locals: { movie_name: params[:movie_name],
#        movie_details: movie_details, genre_studio: genre_studio }
#   end
# end



get "/" do
  redirect "/movies"
end
