###################################################
###
##  File: ww-rest-elvis.rb
##  Desc: The REST interface for Elvis
#

module WoodWing
  module REST
    class Elvis

      attr_accessor base_url

      class Utilities
        class << self

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
              a_string += "#{k}=#{v}"
            end # options.each_pair
          end # url_encode_options

        end # eigenclass
      end # Utilities

      def initialize(my_base_url="http://elvis.upperroom.org/services/")
        base_url = my_base_url
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
        raise "missing path option" unless options.include?(:path)
        url = base_url + "browse"
        url += Utilities.url_encode_options(options)
      end # browse


      # https://elvis.tenderapp.com/kb/api/rest-checkout
      def checkout(options={})
        url = base_url + "checkout"
        url += Utilities.url_encode_options(options)
      end # checkout


      # https://elvis.tenderapp.com/kb/api/rest-copy
      def copy(options={})
        url = base_url + "copy"
        url += Utilities.url_encode_options(options)
      end # copy


      # https://elvis.tenderapp.com/kb/api/rest-create
      def create(options={})
        url = base_url + "create"
        url += Utilities.url_encode_options(options)
      end # create


      # https://elvis.tenderapp.com/kb/api/rest-create_folder
      def create_folder(options={})
        url = base_url + "create_folder"
        url += Utilities.url_encode_options(options)
      end # create_folder


      # https://elvis.tenderapp.com/kb/api/rest-create_relation
      def create_relation(options={})
        url = base_url + "create_relation"
        url += Utilities.url_encode_options(options)
      end # create_relation


      # https://elvis.tenderapp.com/kb/api/rest-create_auth_key
      def create_auth_key(options={})
        url = base_url + "create_auth_key"
        url += Utilities.url_encode_options(options)
      end # create_auth_key


      # https://elvis.tenderapp.com/kb/api/rest-localization
      def localization(options={})
        url = base_url + "localization"
        url += Utilities.url_encode_options(options)
      end # localization


      # https://elvis.tenderapp.com/kb/api/rest-log_usage_stats
      def log_usage_stats(options={})
        url = base_url + "log_usage_stats"
        url += Utilities.url_encode_options(options)
      end # log_usage_stats


      # https://elvis.tenderapp.com/kb/api/rest-login
      def login(options={})
        url = base_url + "login"
        url += Utilities.url_encode_options(options)
      end # login


      # https://elvis.tenderapp.com/kb/api/rest-logout
      def logout(options={})
        url = base_url + "logout"
        url += Utilities.url_encode_options(options)
      end # logout


      # https://elvis.tenderapp.com/kb/api/rest-move
      def move(options={})
        url = base_url + "move"
        url += Utilities.url_encode_options(options)
      end # move


      # https://elvis.tenderapp.com/kb/api/rest-profile
      def profile(options={})
        url = base_url + "profile"
        url += Utilities.url_encode_options(options)
      end # profile


      # https://elvis.tenderapp.com/kb/api/rest-query_stats
      def query_stats(options={})
        url = base_url + "query_stats"
        url += Utilities.url_encode_options(options)
      end # query_stats


      # https://elvis.tenderapp.com/kb/api/rest-remove
      def remove(options={})
        url = base_url + "remove"
        url += Utilities.url_encode_options(options)
      end # remove


      # https://elvis.tenderapp.com/kb/api/rest-remove_relation
      def remove_relation(options={})
        url = base_url + "remove_relation"
        url += Utilities.url_encode_options(options)
      end # remove_relation


      # https://elvis.tenderapp.com/kb/api/rest-rename
      def rename(options={})
        url = base_url + "rename"
        url += Utilities.url_encode_options(options)
      end # rename


      # https://elvis.tenderapp.com/kb/api/rest-revoke_auth_keys
      def revoke_auth_keys(options={})
        url = base_url + "revoke_auth_keys"
        url += Utilities.url_encode_options(options)
      end # revoke_auth_keys


      # https://elvis.tenderapp.com/kb/api/rest-search
      def search(options={})
        url = base_url + "search"
        url += Utilities.url_encode_options(options)
      end # search


      # https://elvis.tenderapp.com/kb/api/rest-undo_checkout
      def undo_checkout(options={})
        url = base_url + "undo_checkout"
        url += Utilities.url_encode_options(options)
      end # undo_checkout


      # https://elvis.tenderapp.com/kb/api/rest-update
      def update(options={})
        url = base_url + "update"
        url += Utilities.url_encode_options(options)
      end # update


      # https://elvis.tenderapp.com/kb/api/rest-update_auth_key
      def update_auth_key(options={})
        url = base_url + "update_auth_key"
        url += Utilities.url_encode_options(options)
      end # update_auth_key


      # https://elvis.tenderapp.com/kb/api/rest-update_bulk
      def update_bulk(options={})
        url = base_url + "update_bulk"
        url += Utilities.url_encode_options(options)
      end # update_bulk


      # https://elvis.tenderapp.com/kb/api/rest-zip_download
      def zip_download(options={})
        url = base_url + "zip_download"
        url += Utilities.url_encode_options(options)
      end # zip_download

    end # Elvis
  end # REST
end # WoodWing

WW = WoodWing
