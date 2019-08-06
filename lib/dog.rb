require 'pry'

class Dog
  attr_accessor :name, :breed, :id
  
  def initialize(hash)
    hash.each {|key, value| self.send("#{key}=", value)}
  end
  
  def save
    if self.id
      self.update
    else
      sql = <<-SQL
        INSERT INTO dogs (name, breed)
        VALUES (?, ?);
      SQL
      DB[:conn].execute(sql, self.name, self.breed)
      @id = DB[:conn].execute("SELECT last_insert_rowid() FROM dogs;")[0][0]
    end
    self
  end
  
  def update
    sql = <<-SQL
      UPDATE dogs SET name = ?, breed = ? WHERE id = ?;
    SQL
    DB[:conn].execute(sql, self.name, self.breed, self.id)
  end
  
  def self.create(hash)
    new_dog = self.new(hash)
    new_dog.save
  end
  
  def self.new_from_db(row)
    hash = Hash.new
    hash[:id] = row[0]
    hash[:name] = row[1]
    hash[:breed] = row[2]
    self.create(hash)
  end
  
  def self.find_by_id(id_num)
    sql = <<-SQL
      SELECT * FROM dogs
      WHERE id = ?;
    SQL
    found = DB[:conn].execute(sql, id_num)[0]
    self.create({:id => found[0], :name => found[1], :breed => [2]})
  end
  
  def self.find_or_create_by(info)
    dog = DB[:conn].execute("SELECT * FROM dogs WHERE name = ? AND breed = ?;", info[:name], info[:breed])
    if dog.empty?
      new_dog = self.create(info)
    else
      info_hash = Hash.new
      info_hash[:id] = dog[0][0]
      info_hash[:name] = dog[0][1]
      info_hash[:breed] = dog[0][2]
      new_dog = self.new(info_hash)
    end
    new_dog
  end
  
  def self.find_by_name(name)
    sql = <<-SQL
      SELECT * FROM dogs
      WHERE name = ?;
    SQL
    self.new_from_db(DB[:conn].execute(sql, name)[0])
  end
  
  def self.create_table
    DB[:conn].execute("DROP TABLE IF EXISTS dogs;")
    sql = <<-SQL
      CREATE TABLE dogs(
      id INTEGER PRIMARY KEY,
      name TEXT,
      breed TEXT);
    SQL
    DB[:conn].execute(sql)
  end
  
  def self.drop_table
    sql = <<-SQL
      DROP TABLE dogs;
    SQL
    DB[:conn].execute(sql)
  end
end