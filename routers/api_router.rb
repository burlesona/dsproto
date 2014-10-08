require_relative './base_router'

module Docserver
  class APIRouter < BaseRouter
    get '/' do
      "These aren't the routes you're looking for."
    end

    # Document Routes
    namespace '/documents' do
      before do
        headers "Content-Type" => "application/json"
        # The following would be necessary to allow content to be fetched directly by JS
        # rather than being relayed by a proxy server.
        # headers "Access-Control-Allow-Origin" => "*"
        # headers "Access-Control-Allow-Methods" => "GET, POST, PUT, PATCH, DELETE, OPTIONS"
        # headers "Access-Control-Allow-Headers" => "Accept, Content-Type"
      end

      # Get Document info?
      get '/:doc_id/?' do
        json document
      end

      # Get Document TOC
      get '/:doc_id/toc/?' do
        json document.toc
      end

      # Read Element
      get '/:doc_id/elements/:element_id/?' do
        json Element.find(params[:element_id])
      end

      # Get options for elements (empty models)
      options '/:doc_id/elements/?' do
        # TBA
      end

      # Create Element
      # Requires element, position, reference_id
      post '/:doc_id/elements/?' do
        # Document handles this to deal with position, indexing and such
        json document.create_element( request_data )
      end

      # Update Element
      # Requires element
      put '/:doc_id/elements/:element_id/?' do
        el = Element.find(params[:element_id])
        json el.update( request_data )
      end

      # Move Element
      # Requires element_id, position, reference_id
      post '/:doc_id/elements/move/?' do
        json document.move_element( request_data )
        204
      end

      # Delete Element
      delete '/:doc_id/elements/:element_id/?' do
        el = Element.find(params[:element_id])
        el.delete!
        204
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

    def document
      @document ||= Document.find(params[:doc_id].to_i)
    end

    def request_data
      request.body.rewind
      JSON.parse request.body.read, symbolize_names: true
    end

    error do |e|
      status = e.respond_to?(:status) ? e.status : 500
      json({error: e.message})
    end
  end
end
