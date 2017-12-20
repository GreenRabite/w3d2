require 'sqlite3'
require 'singleton'

class QuestionsDatabase < SQLite3::Database
  include Singleton

  def initialize
    super('questions.db')
    self.type_translation = true
    self.results_as_hash = true
  end
end

class User
  attr_accessor :fname, :lname
  attr_reader :id

  def self.all
    data = QuestionsDatabase.instance.execute("SELECT * FROM users")
    data.map{|datum| User.new(datum)}
  end

  def self.find_by_id(id)
    identification = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        users
      WHERE
        id = ?
    SQL

    return nil if identification.empty?
    User.new(identification.first)
  end

  def self.find_by_name(fname,lname)
    names = QuestionsDatabase.instance.execute(<<-SQL, fname, lname)
      SELECT
        *
      FROM
        users
      WHERE
        fname = ? AND lname = ?
    SQL

    raise "#{self} not in Database" if names.empty?
    names.map {|name| User.new(name)}
  end

  def authored_questions
    Question.find_by_author_id(self.id)
  end

  def authored_replies
    Reply.find_by_user_id(self.id)
  end

  def followed_questions
    QuestionFollow.followed_questions_for_user_id(self.id)
  end

  def liked_questions
    QuestionLike.liked_questions_for_user_id(self.id)
  end

  def initialize(options)
    @id = options['id']
    @fname = options['fname']
    @lname = options['lname']
  end
end

class Question
  attr_accessor :title, :body, :u_id
  attr_reader :id

  def self.all
    data = QuestionsDatabase.instance.execute("SELECT * FROM questions")
    data.map{|datum| Question.new(datum)}
  end

  def self.find_by_id(id)
    identification = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        questions
      WHERE
        id = ?
    SQL

    return nil if identification.empty?
    Question.new(identification.first)
  end

  def self.find_by_author_id(u_id)
    authors = QuestionsDatabase.instance.execute(<<-SQL, u_id)
      SELECT
        *
      FROM
        questions
      WHERE
        questions.u_id = ?
    SQL
    authors.map { |author| Question.new(author) }
  end

  def author
    author_id = self.u_id
    QuestionsDatabase.instance.execute(<<-SQL, author_id)
    SELECT
      *
    FROM
      users
    WHERE
      id = ?
    SQL
  end

  def replies
    Reply.find_by_question_id(self.id)
  end

  def followers
    QuestionFollow.followers_for_question_id(self.id)
  end

  def self.most_followed(n)
    QuestionFollow.most_followed_questions(n)
  end

  def likers
    QuestionLike.likers_for_question_id(self.id)
  end

  def num_likes
    QuestionLike.num_likes_for_question_id(self.id)
  end

  def initialize(options)
    @id = options['id']
    @title = options['title']
    @body = options['body']
    @u_id = options['u_id']
  end

end

class QuestionFollow
  attr_accessor :q_id, :u_id
  attr_reader :id

  def self.all
    data = QuestionsDatabase.instance.execute("SELECT * FROM question_follows")
    data.map{|datum| QuestionFollow.new(datum)}
  end

  def self.find_by_id(id)
    identification = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        question_follows
      WHERE
        id = ?
    SQL

    return nil if identification.empty?
    QuestionFollow.new(identification.first)
  end

  def self.followers_for_question_id(question_id)
    followers = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        users.*
      FROM
        question_follows
      JOIN
        users ON question_follows.u_id = users.id
      WHERE
        question_follows.q_id = ?
    SQL

    return nil if followers.empty?
    followers.map {|follower| User.new(follower)}
  end

  def self.followed_questions_for_user_id(user_id)
    questions = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        questions.*
      FROM
        question_follows
      JOIN
        questions ON question_follows.q_id = questions.id
      WHERE
        question_follows.u_id = ?
    SQL

    return nil if questions.empty?
    questions.map {|question| Question.new(question)}
  end

  def self.most_followed_questions(n)
    followers = QuestionsDatabase.instance.execute(<<-SQL, n)
      SELECT
        *
      FROM
        question_follows
      JOIN
        questions ON questions.id = question_follows.q_id
      GROUP BY
        question_follows.q_id
      HAVING
        COUNT(question_follows.q_id)
      ORDER BY
        question_follows.q_id DESC
      LIMIT
        ?
    SQL
    # p followers
    return nil if followers.empty?
    followers.map {|follower| Question.new(follower)}
  end

  def initialize(options)
    @id = options['id']
    @q_id = options['q_id']
    @u_id = options['u_id']
  end
end

class Reply
  attr_accessor :body, :q_id, :u_id, :parent_id
  attr_reader :id

  def self.all
    data = QuestionsDatabase.instance.execute("SELECT * FROM replies")
    data.map{|datum| Reply.new(datum)}
  end

  def self.find_by_id(id)
    identification = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        replies
      WHERE
        id = ?
    SQL

    return nil if identification.empty?
    Reply.new(identification.first)
  end

  def self.find_by_user_id(u_id)
    authors = QuestionsDatabase.instance.execute(<<-SQL, u_id)
      SELECT
        *
      FROM
        replies
      WHERE
        replies.u_id = ?
    SQL
    # return nil if author.empty?
    authors.map {|author| Reply.new(author)}
  end

  def self.find_by_question_id(q_id)
    authors = QuestionsDatabase.instance.execute(<<-SQL, q_id)
      SELECT
        *
      FROM
        replies
      WHERE
        replies.q_id = ?
    SQL
    # return nil if author.empty?
    authors.map {|author| Reply.new(author)}
  end

  def author
    author_id = self.u_id
    QuestionsDatabase.instance.execute(<<-SQL, author_id)
    SELECT
      *
    FROM
      users
    WHERE
      id = ?
    SQL
  end

  def question
    question_id = self.q_id
    QuestionsDatabase.instance.execute(<<-SQL, question_id)
    SELECT
      *
    FROM
      questions
    WHERE
      id = ?
    SQL
  end

  def parent_reply
    parent_id = self.parent_id
    return "#{self} has no parent" if parent_id.nil?
    reply=QuestionsDatabase.instance.execute(<<-SQL, parent_id)
    SELECT
      *
    FROM
      replies
    WHERE
      id = ?
    SQL
    Reply.new(reply.first)
  end

  def child_replies
    child_reply = QuestionsDatabase.instance.execute(<<-SQL, self.id)
    SELECT
      *
    FROM
      replies
    WHERE
      parent_id = ?
    SQL
    child_reply.map {|reply| Reply.new(reply)}
  end

  def initialize(options)
    @id = options['id']
    @body = options['body']
    @q_id = options['q_id']
    @u_id = options['u_id']
    @parent_id = options['parent_id']
  end
end

class QuestionLike
  attr_accessor :q_id, :u_id
  attr_reader :id

  def self.all
    data = QuestionsDatabase.instance.execute("SELECT * FROM question_likes")
    data.map{|datum| QuestionLike.new(datum)}
  end

  def self.find_by_id(id)
    identification = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        question_likes
      WHERE
        id = ?
    SQL

    return nil if identification.empty?
    QuestionLike.new(identification.first)
  end

  def self.likers_for_question_id(q_id)
    likers = QuestionsDatabase.instance.execute(<<-SQL, q_id)
      SELECT
        users.*
      FROM
        question_likes
      JOIN
        users ON users.id = question_likes.u_id
      WHERE
        question_likes.q_id = ?
    SQL

    return nil if likers.empty?
    likers.map{|liker| User.new(liker)}
  end

  def self.num_likes_for_question_id(q_id)
    likes = QuestionsDatabase.instance.execute(<<-SQL, q_id)
      SELECT
        COUNT(*) AS most_liked
      FROM
        question_likes
      JOIN
        questions ON questions.id = question_likes.q_id
      WHERE
        question_likes.q_id = ?
      GROUP BY
        questions.id
    SQL
    "The number of likes for question id #{q_id} is #{likes.first['most_liked']}"
    # return nil if likers.empty?
    # likers.map{|liker| User.new(liker)}
  end

  def self.liked_questions_for_user_id(u_id)
    questions = QuestionsDatabase.instance.execute(<<-SQL, u_id)
      SELECT
        *
      FROM
        question_likes
      JOIN
        questions ON questions.id = question_likes.q_id
      WHERE
        question_likes.u_id = ?
    SQL
    Question.new(questions.first)
    # "The number of likes for question id #{q_id} is #{likes.first['most_liked']}"
    # return nil if likers.empty?
    # likers.map{|liker| User.new(liker)}
  end

  def initialize(options)
    @id = options['id']
    @q_id = options['q_id']
    @u_id = options['u_id']
  end
end
