def create
  create_table(:books) do
    String :id
    String :path, unique: true
    String :title, null: false
    String :authors
    String :translators
    Integer :year
    String :isbn
    String :publisher
    Integer :amount
    String :annotation
    String :contents
    String :outer_id
    DateTime :mtime
    Date :added
  end
end
