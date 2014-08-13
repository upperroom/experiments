###################################################
###
##  File: ww-rest-elvis.rb
##  Desc: The REST interface for Elvis
#

require "url_safe_base64"

require 'rest_client'
require 'multi_json'

module WoodWing
  module REST
    class Elvis

      attr_accessor :base_url

      # SMELL: Why is this error any more special than the others?
      class ConcurrentModificationException < StandardError; end

      COMMANDS = {
        # method name       URL Resource        Required Parameters
        browse:             ["browse",          [:path]],
        checkout:           ["checkout",        []],
        copy:               ["copy",            [:source, :target]],
        create:             ["create",          [:assetPath, :Filedata]],
        create:             ["create",          []],
        create_auth_key:    ["create_auth_key", []],
        create_collection:  ["create",          [:assetPath]],
        create_relation:    ["create_relation", []],
        create_folder:      ["createFolder",    [:path]],
        localization:       ["localization",    []],
        log_usage_stats:    ["log_usage_stats", []],
        login:              ["login",           []],
        logout:             ["logout",          []],
        move:               ["move",            [:source, :target]],
        profile:            ["profile",         []],
        query_stats:        ["queryStats",      []],
        remove:             ["remove",          []],
        remove_folder:      ["remove",          [:folderPath]],
        remove_relation:    ["remove_relation", []],
        revoke_auth_keys:   ["revoke_auth_keys",[]],
        search:             ["search",          [:q]],
        undo_checkout:      ["undo_checkout",   []],
        update:             ["update",          []],
        update_auth_key:    ["update_auth_key", []],
        update_bulk:        ["update_bulk",     []],
        zip_download:       ["zip_download",    []]
      }

      class Utilities

        # Utility class to check permissions 'mask' for available permissions.
        # The permissions mask consists of a string with one character for
        # every permission available in Elvis: VPUMERXCD

        class Pmask
          PERMISSIONS = {
            'V' => 'VIEW',
            'P' => 'VIEW_PREVIEW',
            'U' => 'USE_ORIGINAL',
            'M' => 'EDIT_METADATA',
            'E' => 'EDIT',
            'R' => 'RENAME',
            'X' => 'MOVE',
            'C' => 'CREATE',
            'D' => 'DELETE',
          }

          def initialize(pmask='')
            @pmask = pmask
          end

          def verbose
            v=[]
            @pmask.each_char{|c| v<<PERMISSIONS[c]}
            return v.join(', ')
          end

          define_method('can_view?')          { @pmask.include? 'V' }
          define_method('can_view_preview?')  { @pmask.include? 'P' }
          define_method('can_use_original?')  { @pmask.include? 'U' }
          define_method('can_edit_metadata?') { @pmask.include? 'M' }
          define_method('can_edit?')          { @pmask.include? 'E' }
          define_method('can_rename?')        { @pmask.include? 'R' }
          define_method('can_move?')          { @pmask.include? 'X' }
          define_method('can_create?')        { @pmask.include? 'C' }
          define_method('can_delete?')        { @pmask.include? 'D' }
        end # class Pmask


        class << self

          # SMELL: Is this really necessary with RestClient ?
          def url_encode_options(options)
            raise "Invalid parameter class: expected Hash" unless Hash == options.class
            a_string  = ''
            first_one = true
            options.each_pair do |k, v|
              if first_one
                a_string += '?'
                first_one = false
              else
                a_string += '&'
              end
              # a_string += "#{k}=#{String == v.class ? v.gsub(' ','%20') : v}"
              a_string += "#{k}=#{URI::encode(v)}"
            end # options.each_pair
            #debug_me{:a_string} if debug?
            return a_string
          end # url_encode_options


          # encode the username and password for use on the URL for login

          def encode_login(username='guest', password='guest')
            {
              authcred:     UrlSafeBase64.encode64("#{username}:#{password}"),
              authpersist:  'true',
              authclient:   'api_ruby'
            }
          end


          # raise ArgumentError if required options are not present

          def demand_required_options!(command, options)
            raise ArgumentError unless Symbol == command.class
            raise ArgumentError unless Hash == options.class
            raise ArgumentError unless WW::REST::Elvis::COMMANDS.include?(command)
            required_options = WW::REST::Elvis::COMMANDS[command][1]
            answer = true
            return(answer) if required_options.empty?
            required_options.each do |ro|
              answer &&= options.include?(ro)
            end
            raise "ArgumentError: #{caller.first.split().last} requires #{required_options.join(', ')}" unless answer
          end

        end # eigenclass
      end # class Utilities


      def initialize(my_base_url=ENV['ELVIS_API_URL'])
        @base_url = my_base_url
      end


      def get_response(url=nil,options={})
        url += Utilities.url_encode_options(options) unless options.empty?

debug_me{[:url, :options ]} if $DEBUG

        response = RestClient.get(url)     # , options)
        if String == response.class
          response = MultiJson.load(  response,
                                      :symbolize_keys => true)
          # debug_me(){[ :url, :response ]}
          if response.include?(:errorcode)
            if 401 == response[:errorcode]     &&
              response[:message].include?('ConcurrentModificationException')
              raise ConcurrentModificationException
            else
              error_condition = "ERROR #{response[:errorcode]}: #{response[:message]}"
              raise error_condition
            end
          end
        end

        return response
      end


      def get_response_using_post(url=nil,options={})
        # url += Utilities.url_encode_options(options) unless options.empty?

debug_me{[:url, :options ]} if $DEBUG

        response = RestClient.post(url, options)

        if String == response.class
          response = MultiJson.load(  response,
                                      :symbolize_keys => true)
          # debug_me(){[ :url, :response ]}
          if response.include?(:errorcode)
            if 401 == response[:errorcode]     &&
              response[:message].include?('ConcurrentModificationException')
              raise ConcurrentModificationException
            else
              error_condition = "ERROR #{response[:errorcode]}: #{response[:message]}"
              raise error_condition
            end
          end
        end

        return response
      end


      # https://elvis.tenderapp.com/kb/api/rest-browse
      #
      # browse folders and show their subfolders and collections,
      # similar to how folder browsing works in the Elvis desktop client.
      #
      # Note: Even though it is possible to return the assets in folders,
      #       doing so is not advised. The browse call does not limit the
      #       number of results, so if there are 10000 assets in a folder
      #       it will return all of them. It is better to use a search to
      #       find the assets in a folder and fetch them in pages.
      #
      # http://yourserver.com/services/browse
      #   ?path=<assetPath>
      #   &fromRoot=<folderPath>
      #   &includeFolders=<true|false>
      #   &includeAssets=<true|false>
      #   &includeExtensions=<comma-delimited extensions>
      #
      # Options
      #   path    (Required) The path to the folder in Elvis you want to list.
      #           Make sure the URL is properly URL-encoded, for example: spaces should
      #           often be represented as %20.
      #
      #   fromRoot  Allows returning multiple levels of folders with their
      #             children. When specified, this path is listed, and all folders
      #             below it up to the 'path' will have their children returned as well.
      #
      #             This ability can be used to initialize an initial path in a
      #             column tree folder browser with one server call.
      #
      #             Optional. When not specified, only the children of the specified
      #             'path' will be returned.
      #
      #             Available since Elvis 2.6
      #
      #   includeFolders  Indicates if folders should be returned.
      #                   Optional. Default is true.
      #
      #   includeAsset  Indicates if files should be returned.
      #                 Optional. Default is true, but filtered to
      #                 only include 'container' assets.
      #
      #   includeExtensions   A comma separated list of file extensions to
      #                       be returned. Specify 'all' to return all file types.
      #                       Optional. Default includes all 'container'
      #                       assets: .collection, .dossier, .task

      def browse(options={})
        Utilities.demand_required_options!( :browse, options )
        url = base_url + "browse"
        response = get_response(url, options)
      end # browse


      # https://elvis.tenderapp.com/kb/api/rest-checkout
      def checkout(options={})
        url = base_url + "checkout"
        response = get_response(url, options)
      end # checkout


      # https://elvis.tenderapp.com/kb/api/rest-copy
      def copy(options={})
        Utilities.demand_required_options!( :copy, options )
        url = base_url + "copy"
        response = get_response(url, options)
      end # copy


      # https://elvis.tenderapp.com/kb/api/rest-create
      # Upload and create an asset.
      #
      # This call will create a new asset in Elvis. It can be used to upload files
      # into Elvis. It can also be used to create 'virtual' assets like collections.
      # In that case no file has to be uploaded and Elvis will create a 0 kb
      # placeholder for the virtual asset.
      #
      # When you want to create a new asset, certain metadata is required. The
      # metadata is needed to determine where the file will be stored in Elvis.
      #
      # http://yourserver.com/services/create
      #   ?Filedata=<multipart/form-data encoded file>
      #   &metadata=<JSON encoded metadata>
      #   &<Elvis metadata field name>=<value>
      #   &nextUrl=<next URL>
      #
      # Options
      #
      #   Filedata  The file to be created in Elvis.  If you do not specify a
      #             filename explicitly through the metadata, the filename of
      #             the uploaded file will be used.
      #             NOTE: The parameter is named "Filedata" because that is the
      #                   standard name used by flash uploads. This makes it easy
      #                   to use flash uploaders to upload batches of files to Elvis.
      #             Optional. If omitted, a 0kb placeholder file will be created.
      #             See the method create_collection()
      #
      #   metadata  A JSON encoded object with properties that match Elvis metadata
      #             field names. This metadata will be set on the asset in Elvis.
      #             Optional. You can also use parameters matching Elvis field names.
      #
      #   *   Any parameter matching an Elvis metadata field name will be used as
      #       metadata. This metadata will be set on the asset in Elvis.
      #       Optional. You also use the 'metadata' parameter.
      #
      #   nextUrl   When specified, the service will send a 301 redirect to this
      #             URL when it is completed successfully. If you place '${id}' in
      #             the URL, it will be replaced with the Elvis asset id of the
      #             created asset.
      #             Optional. If omitted, a simple 200 OK status code will be returned

      def create(options={})
        Utilities.demand_required_options!( :create, options )
        options.merge!( { multipart: true } )
        url = base_url + "create"
        response = get_response_using_post(url, options)
      end # create

      alias :create_file :create
      alias :upload_file :create
      alias :import_file :create
      alias :create_asset :create
      alias :upload_asset :create
      alias :import_asset :create


      # No file is uploaded.  A placehold asset is created with the
      # associated metadata
      def create_collection(options={})
        Utilities.demand_required_options!( :create_collection, options )
        url = base_url + "create"
        options.merge!( {assetType: 'collection'} )
        response = get_response(url, options)
      end # create


      # https://elvis.tenderapp.com/kb/api/rest-create_folder
      def create_folder(options={})
        Utilities.demand_required_options!( :create_folder, options )
        url = base_url + "createFolder"
        response = get_response(url, options)
      end # create_folder


      # https://elvis.tenderapp.com/kb/api/rest-create_relation
      def create_relation(options={})
        url = base_url + "create_relation"
        response = get_response(url, options)
      end # create_relation


      # https://elvis.tenderapp.com/kb/api/rest-create_auth_key
      def create_auth_key(options={})
        url = base_url + "create_auth_key"
        response = get_response(url, options)
      end # create_auth_key


      # https://elvis.tenderapp.com/kb/api/rest-localization
      def localization(options={})
        url = base_url + "localization"
        response = get_response(url, options)
      end # localization


      # https://elvis.tenderapp.com/kb/api/rest-log_usage_stats
      def log_usage_stats(options={})
        url = base_url + "log_usage_stats"
        response = get_response(url, options)
      end # log_usage_stats


      # https://elvis.tenderapp.com/kb/api/rest-login
      def login(options={})
        url = base_url + "login"
        response = get_response(url, options)
      end # login


      # https://elvis.tenderapp.com/kb/api/rest-logout
      def logout(options={})
        url = base_url + "logout"
        response = get_response(url, options)
      end # logout


      # https://elvis.tenderapp.com/kb/api/rest-move
      def move(options={})
        Utilities.demand_required_options!( :move, options )
        url = base_url + "move"
        response = get_response(url, options)
      end # move

      alias :rename :move


      # https://elvis.tenderapp.com/kb/api/rest-profile
      def profile(options={})
        url = base_url + "profile"
        response = get_response(url, options)
      end # profile


      # https://elvis.tenderapp.com/kb/api/rest-query_stats
      def query_stats(options={})
        url = base_url + "queryStats"
        response = get_response(url, options)
      end # query_stats


      # https://elvis.tenderapp.com/kb/api/rest-remove
      def remove(options={})
        url = base_url + "remove"
        response = get_response(url, options)
      end # remove

      alias :delete :remove


      # https://elvis.tenderapp.com/kb/api/rest-remove
      def remove_folder(options={})
        Utilities.demand_required_options!( :remove_folder, options )
        url = base_url + "remove"
        response = get_response(url, options)
      end # remove_folder

      alias :delete_folder :remove_folder


      # https://elvis.tenderapp.com/kb/api/rest-remove_relation
      def remove_relation(options={})
        url = base_url + "remove_relation"
        response = get_response(url, options)
      end # remove_relation

      alias :delete_relation :remove_relation


      # https://elvis.tenderapp.com/kb/api/rest-revoke_auth_keys
      def revoke_auth_keys(options={})
        url = base_url + "revoke_auth_keys"
        response = get_response(url, options)
      end # revoke_auth_keys


      # https://elvis.tenderapp.com/kb/api/rest-search
      # Search assets in Elvis using all of the powerful search functions provided
      # by the Elvis search engine. You can execute all possible queries and even
      # use faceted search.
      #
      # Returned information can be formatted as JSON, XML or HTML to support any
      # kind of environment for clients.
      #
      # Apart from all sorts of metadata about the assets, the results returned
      # by a search call also contain ready-to-use URLs to the thumbnail, preview
      # and original file. This makes it extremely easy to display rich visual results.
      #
      # http://yourserver.com/services/search
      #     ?q=<query>
      #     &start=<first result>
      #     &num=<max result hits to return>
      #     &sort=<comma-delimited sort fields>
      #     &metadataToReturn=<comma-delimited fields>
      #     &facets=<comma-delimited fields>
      #     &facet.<field>.selection=<comma-delimited values>
      #     &format=<json|xml|html>
      #     &appendRequestSecret=<true|false>
      #
      # Options
      #   q   (Required) The query to search for, see the query syntax guide
      #       for details.  https://elvis.tenderapp.com/kb/technical/query-syntax
      #       Recap:  supports wildcards: *? logical: AND && OR ||
      #               prefix terms with + to require - to remove
      #               suffix terms with ~ to include similar (eg. spelling errors)
      #               terms seperated by spaces default to an AND condition
      #               use "double quotes" to search for phrases.
      #               All searches are case insensitive.
      #
      #   start   First hit to be returned. Starting at 0 for the first hit. Used
      #           to skip hits to return 'paged' results. Optional. Default is 0.
      #
      #   num   Number of hits to return. Specify 0 to return no hits, this can be
      #         useful if you only want to fetch facets data. Optional. Default is 50.
      #
      #   sort  The sort order of returned hits. Comma-delimited list of fields to
      #         sort on.  By default, date/time fields and number fields are sorted
      #         descending. All other fields are sorted ascending. To explicitly
      #         specify sort order, append "-desc" or "-asc" to the field.
      #           Some examples:
      #             sort=name
      #             sort=rating
      #             sort=fileSize-asc
      #             sort=status,assetModified-asc
      #         A special sort case is "relevance". This lets the search engine
      #         determine sorting based on the relevance of the asset against
      #         the search query. Relevance results are always returned descending.
      #         Optional. Default is assetCreated-desc.
      #
      # metadataToReturn  Comma-delimited list of metadata fields to return in hits.
      #                   It is good practice to always specify just the metadata
      #                   fields that you need. This will make the searches faster
      #                   because less data needs to be transferred over the network.
      #                   Example: metadataToReturn=name,rating,assetCreated
      #                   Specify "all", or omit to return all available metadata.
      #                   Example:  metadataToReturn=all
      #                             metadataToReturn=
      #                   Optional. Default returns all fields.
      #
      # facets  Comma-delimited list fields to return facet for.
      #         Example: facets=tags,assetDomain
      #         Selected values for a facet must be specified with a
      #         "facet.<field>.selection" parameter. Do not add selected items to
      #         the query since that will cause incorrect facet filtering.
      #         Note: Only fields that are un_tokenized or tokenized with
      #         pureLowerCase analyzer can be used for faceted search
      #         Optional. Default returns no facets.
      #
      # facet.<field>.selection   Comma-delimited list of values that should
      #                           be 'selected' for a given facet.
      #                           Example:  facet.tags.selection=beach
      #                                     facet.assetDomain.selection=image,video
      #                           Optional.
      #
      # format  Response format to return, either json, xml or html.
      #         json  format is lightweight and very suitable for consumption
      #               using AJAX and JavaScript.
      #         html  format is the easiest way to embed results in HTML pages,
      #               but is heavier and less flexible than using a HitRenderer
      #               from our open-source JavaScript library.
      #         xml   format is the same as returned by the Elvis SOAP webservice
      #               search operation. This format is suitable for environments
      #               that do not support JSON parsing and work better with XML.
      #               When you use format=xml, error responses will also be returned
      #               in xml format.
      #         Optional. Default is json.
      #
      #   appendRequestSecret   When set to true will append an encrypted code to
      #                         the thumbnail, preview and original URLs. This is
      #                         useful when the search is transformed to HTML by an
      #                         intermediary (like a PHP or XSLT) and is then served
      #                         to a web browser that is not authenticated against
      #                         the server.
      #                         Optional. Default is false.
      #
      # RETURNED VALUE
      # ==============
      #
      # An array of hits in JSON, XML or HTML format. Each item in the array has
      # the following properties.
      #
      #   firstResult     Index of the first result that is returned.
      #   maxResultHits   Maximum number of hits that are returned.
      #   totalHits       Total hits found by the search.
      #
      # hits
      #
      #   id            Unique ID of the asset in Elvis.
      #   permissions   String that indicates the permissions the current user has
      #                 for the asset.
      #   thumbnailUrl  A ready to use URL to display the thumbnail of an asset.
      #                 Only available for assets that have a thumbnail.
      #   previewUrl    A ready to use URL to display the default preview of an
      #                 asset. The type of preview depends on the asset type.
      #                 Only available for assets that have a preview.
      #   originalUrl   A ready to use URL to download the original asset.
      #                 This URL will only work if the user has the 'use original'
      #                 permission for this asset. This can be checked with the
      #                 'permissions' property.
      #   metadata      An object with metadata that was requested to be returned.
      #                 Some metadata will always be returned.
      #
      # Fields that have date or datetime values and the field fileSize contain
      # both the actual numerical value and a formatted value.

      def search(options={})
        Utilities.demand_required_options!( :search, options )
        url = base_url + "search"
        response = get_response(url, options)
      end # search

      alias :find :search


      # https://elvis.tenderapp.com/kb/api/rest-undo_checkout
      def undo_checkout(options={})
        url = base_url + "undo_checkout"
        response = get_response(url, options)
      end # undo_checkout

      alias :abort_checkout :undo_checkout


      # https://elvis.tenderapp.com/kb/api/rest-update
      def update(options={})
        url = base_url + "update"
        response = get_response(url, options)
      end # update

      alias :replace :update


      # https://elvis.tenderapp.com/kb/api/rest-update_auth_key
      def update_auth_key(options={})
        url = base_url + "update_auth_key"
        response = get_response(url, options)
      end # update_auth_key

      alias :replace_auth_key :update_auth_key


      # https://elvis.tenderapp.com/kb/api/rest-update_bulk
      def update_bulk(options={})
        url = base_url + "update_bulk"
        response = get_response(url, options)
      end # update_bulk

      alias :replace_bulk :update_bulk
      alias :bulk_update :update_bulk


      # https://elvis.tenderapp.com/kb/api/rest-zip_download
      def zip_download(options={})
        url = base_url + "zip_download"
        response = get_response(url, options)
      end # zip_download

      alias :download_zip :zip_download

    end # Elvis
  end # REST
end # WoodWing

WW      = WoodWing
WwRest  = WoodWing::REST

__END__
##################################################
## Testing Related Stuff

$elvis = WW::REST::Elvis.new

def send_command( command_name, options, e=$elvis )
  o = options.merge( WW::REST::Elvis::Utilities.encode_login(
    $options[:elvis_user],
    $options[:elvis_pass]) )
  e.send(command_name, o)
end


def test_it( command_name, options, e=$elvis )
  if debug?
    puts "="*45
    puts "Command: #{command_name}"
  end
  r = send_command( command_name, options, e)
  if debug?
    puts "Response is of class: #{r.class}  size: #{r.size}"
    pp r
  end
  return r
end

