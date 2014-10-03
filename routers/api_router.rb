require_relative './base_router'

module Docserver
  class APIRouter < BaseRouter
    get '/' do
      "These aren't the routes you're looking for."
    end

    # Document Routes
    namespace '/documents' do
      # Get Document info?
      get '/:doc_id/?' do
        "Document info for #{params[:doc_id]}"
      end

      # Get Document TOC
      get '/:doc_id/toc/?' do
        json Document.find(params[:doc_id].to_i).toc
      end

      # Read Element
      get '/:doc_id/elements/:element_id' do
        json Element.find(params[:element_id])
      end

      # Get options for elements (empty models)
      options '/:doc_id/elements' do
      end

      # Create Element
      post '/:doc_id/elements' do
      end

      # Update Element
      put '/:doc_id/elements/:element_id' do
      end

      # Move Element
      post '/:doc_id/elements/move' do
      end

      # Delete Element
      delete '/:doc_id/elements/:element_id' do
      end

      # (why can't a PUT on the element work for this?)
      #Change element title
      #put '/:doc_id/elements/:element_id/title' do
      #end

      #(why not a put to /:doc_id?)
      #Change Book Title
      #put '/:doc_id/title' do
      #end

      # Does this belong in the Consumer (scholar) or the API(docserver)?
      #Upload Document
      #post '/:doc_id/upload/:reference_id' do
      #end
    end

    error do |e|
      status = e.respond_to?(:status) ? e.status : 500
      json({error: e.message})
    end
  end
end
