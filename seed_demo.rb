# One-off seed script for the BSYSTEM theme preview — run via `bin/rails
# runner`. Not part of the fork's payload (the theme CSS is); this only
# exists to put enough real data on screen (issues at every status/priority,
# subtasks, a wiki page, news, a forum thread, documents, time entries, a
# second member) to actually see the theme working across the surfaces an
# empty project or single-author project can't show.

project = Project.find_by(identifier: "bsystem-demo") or raise "run after creating the bsystem-demo project"
admin = User.find_by(login: "admin") or raise "no admin user"

tracker_bug = Tracker.find_by(name: "Помилка") || Tracker.first
tracker_feature = Tracker.find_by(name: "Властивість") || Tracker.first
tracker_support = Tracker.find_by(name: "Підтримка") || Tracker.first
[tracker_bug, tracker_feature, tracker_support].uniq.each do |t|
  project.trackers << t unless project.trackers.include?(t)
end

version = project.versions.find_or_create_by!(name: "v1.0") do |v|
  v.status = "open"
  v.due_date = Date.today + 30
end

# --- a second member so "assignee" isn't always admin -----------------
dev = User.find_or_create_by!(login: "o.melnyk") do |u|
  u.firstname = "Олена"
  u.lastname = "Мельник"
  u.mail = "o.melnyk@example.test"
  u.language = "uk"
  u.status = User::STATUS_ACTIVE
  u.password = "BsystemPreview123!"
  u.password_confirmation = "BsystemPreview123!"
end
dev.save!(validate: false) if dev.new_record?

developer_role = Role.find_by(name: "Розробник")
manager_role = Role.find_by(name: "Менеджер")
[[admin, manager_role], [dev, developer_role]].each do |user, role|
  next unless role
  next if project.members.exists?(user_id: user.id)
  Member.create!(project: project, user: user, roles: [role])
end

statuses = IssueStatus.all.index_by(&:name)
priorities = IssuePriority.all.index_by(&:name)

seed_issues = [
  ["Налаштувати CI/CD пайплайн", "Новий", "Високий", tracker_support, admin],
  ["Виправити помилку авторизації", "В процесі", "Негайний", tracker_bug, dev],
  ["Оновити документацію API", "Новий", "Низький", tracker_support, dev],
  ["Провести код-рев'ю модуля оплат", "Вирішено", "Нормальний", tracker_bug, admin],
  ["Мігрувати базу даних на новий сервер", "В процесі", "Високий", tracker_support, admin],
  ["Додати темну тему в адмін-панель", "Зачинено", "Нормальний", tracker_feature, dev],
  ["Налаштувати моніторинг помилок", "Зворотний зв'язок", "Високий", tracker_support, admin],
  ["Прибрати застарілий ендпоінт /v1/legacy", "Відмовлено", "Низький", tracker_feature, dev],
]

created = {}
seed_issues.each do |subject, status_name, priority_name, tracker, assignee|
  issue = project.issues.find_by(subject: subject)
  next if issue
  issue = Issue.new(
    project: project,
    tracker: tracker,
    subject: subject,
    description: "Тестові дані для перевірки BSYSTEM-теми.",
    author: admin,
    assigned_to: assignee,
    status: statuses[status_name] || IssueStatus.first,
    priority: priorities[priority_name] || IssuePriority.first,
    fixed_version: version,
  )
  issue.save!(validate: false)
  created[subject] = issue
end

# --- a couple of subtasks, so the issue tree/hierarchy has depth ------
parent = project.issues.find_by(subject: "Мігрувати базу даних на новий сервер")
if parent
  [
    ["Зробити бекап поточної БД", "Вирішено"],
    ["Перевірити цілісність даних після міграції", "Новий"],
  ].each do |subject, status_name|
    next if project.issues.exists?(subject: subject)
    sub = Issue.new(
      project: project,
      tracker: parent.tracker,
      subject: subject,
      description: "Підзадача для перевірки ієрархії задач.",
      author: admin,
      assigned_to: dev,
      status: statuses[status_name] || IssueStatus.first,
      priority: priorities["Нормальний"] || IssuePriority.first,
      parent_issue_id: parent.id,
    )
    sub.save!(validate: false)
  end
end

# --- time entries against a couple of issues ---------------------------
activity = TimeEntryActivity.find_by(name: "Розробка") || TimeEntryActivity.first
logged_issue = project.issues.find_by(subject: "Виправити помилку авторизації")
if logged_issue && project.time_entries.where(issue_id: logged_issue.id).empty? && activity
  [[dev, 3.5, Date.today - 2], [admin, 1.0, Date.today - 1]].each do |user, hours, date|
    TimeEntry.create!(
      project: project,
      issue: logged_issue,
      user: user,
      hours: hours,
      activity: activity,
      spent_on: date,
      comments: "Тестовий запис часу для перевірки теми.",
    )
  end
end

# --- news -----------------------------------------------------------
if project.news.empty?
  News.create!(
    project: project,
    author: admin,
    title: "Реліз v1.0",
    summary: "Перший тестовий реліз для демонстрації BSYSTEM-теми.",
    description: "## Що нового\n\n- Темна тема інтерфейсу\n- Оновлена панель адміністрування\n- Виправлені помилки авторизації",
  )
  News.create!(
    project: project,
    author: dev,
    title: "Заплановане технічне обслуговування",
    summary: "Коротке вікно недоступності для міграції бази даних.",
    description: "Сервіс буде недоступний орієнтовно 30 хвилин під час нічного вікна обслуговування.",
  )
end

# --- forum / board with a couple of replies -----------------------
project.enabled_module_names |= ["boards"]
board = project.boards.find_or_create_by!(name: "Загальне обговорення") do |b|
  b.description = "Питання та обговорення щодо проєкту BSYSTEM Demo."
end
if board.topics.empty?
  topic = Message.create!(
    board: board,
    author: admin,
    subject: "Ласкаво просимо до проєкту BSYSTEM Demo",
    content: "Це тестова тема форуму для перевірки теми оформлення.",
  )
  Message.create!(
    board: board,
    author: dev,
    subject: "RE: Ласкаво просимо до проєкту BSYSTEM Demo",
    content: "Дякую! Тема виглядає узгоджено з рештою інтерфейсу.",
    parent: topic,
  )
end

# --- documents --------------------------------------------------------
if project.documents.empty?
  category = DocumentCategory.find_by(name: "Технічна документація") || Enumeration.where(type: "DocumentCategory").first
  Document.create!(
    project: project,
    category: category,
    title: "Архітектурні нотатки",
    description: "Тестовий документ для перевірки теми на сторінці документів.",
  )
end

# --- wiki page -------------------------------------------------------
WikiPage.transaction do
  wiki = project.wiki || Wiki.create!(project: project, start_page: "Home")
  page = wiki.find_or_new_page("Home")
  page.wiki = wiki
  page.save! if page.new_record?
  content = page.content || WikiContent.new(page: page)
  content.text = <<~MD
    # BSYSTEM Demo

    Це тестова Wiki-сторінка для перевірки теми **BSYSTEM**.

    ## Приклади форматування

    - Марковані списки
    - *Курсив* та **жирний** текст
    - `код`

    | Колонка A | Колонка B |
    |---|---|
    | 1 | 2 |
    | 3 | 4 |
  MD
  content.author = admin
  content.page = page
  content.save!
end

puts "Seeded: #{project.issues.count} issues, #{project.news.count} news, " \
     "#{project.time_entries.count} time entries, #{project.documents.count} documents, " \
     "#{board.topics.count} forum topics, wiki page, version #{version.name}, " \
     "#{project.members.count} members"
