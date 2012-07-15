require 'sinatra'
require 'sinatra/flash'
require 'sinatra/redirect_with_flash'
require 'data_mapper'
require 'builder'

enable :sessions

SITE_TITLE = "Recall"
SITE_DESCRIPTION = "'cause you're too busy too remember'"

DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/recall.db")

class Note
    include DataMapper::Resource
    property :id, Serial
    property :content, Text, :required => true
    property :complete, Boolean, :required => true, :default => false
    property :created_at, DateTime
    property :updated_at, DateTime
end

DataMapper.finalize.auto_upgrade!

helpers do
    include Rack::Utils
    alias_method :h, :escape_html
end

# show homepage
get '/' do
    @notes = Note.all :order => :id.desc
    @title = 'All Notes'
    if @notes.empty?
        flash[:error] = 'No notes found. Add your first below.'
    end
    erb :home
end

# Create a new note
post '/' do
    n = Note.new
    n.content = params[:content]
    n.created_at = Time.now
    n.updated_at = Time.now
    if n.save
        redirect '/', :notice => 'Note created successfully.'
    else
        redirect '/', :error => 'Failed to save note.'
    end
end

# Create rss feed with builder
get '/rss.xml' do
    @notes = Note.all :order => :id.desc
    builder :rss
end

# display page to edit a note
get '/:id' do
    @note = Note.get params[:id]
    @title = "Edit note ##{params[:id]}"
    if @note
        erb :edit
    else
        redirect '/', error => "Can't find that note."
    end
end

# save the edit (notice usage of HTTP PUT)
put '/:id' do
    n = Note.get params[:id]
    unless n
        redirect '/', :error => "Can't find that note."
    end
    n.content = params[:content]
    n.complete = params[:complete] ? 1 : 0
    n.updated_at = Time.now
    if n.save
        redirect '/', :notice => 'Note updated successfully.'
    else
        redirect '/', :error => 'Error updating note.'
    end
end

# show post delete page
get '/:id/delete' do
    @note = Note.get params[:id]
    @title = "Confirm deletion of note ##{params[:id]}"
    if @note
        erb :delete
    else
        redirect '/', :error => "Can't find that note."
    end
end

# delete the post (note usage of HTTP DELETE)
delete '/:id' do
    n = Note.get params[:id]
    if n.destroy
        redirect '/', :notice => 'Note deleted successfully.'
    else
        redirect '/', :error => 'Error deleting note.'
    end
end

# mark note as complete
get '/:id/complete' do
    n = Note.get params[:id]
    unless n
        redirect '/', :error => "Can't find that note."
    end
    n.complete = n.complete ? 0 : 1 #flip it
    n.updated_at = Time.now
    if n.save
        complete = "Note marked as complete."
        if !n.complete
            complete = "Note marked as not-complete."
        end
        redirect '/', :notice => complete
    else
        redirect '/', :error => "Error marking note as complete."
    end
end


