# One-off seed script for the BSYSTEM theme preview — run via `bin/rails
# runner`. Not part of the fork's payload (the theme CSS is); this only
# exists to put enough real data on screen (issues at every status/priority,
# a wiki page, a version/milestone, a second project) to actually see the
# theme working across the surfaces a screenshot of an empty project can't
# show.

project = Project.find_by(identifier: "bsystem-demo") or raise "run after creating the bsystem-demo project"
admin = User.find_by(login: "admin") or raise "no admin user"

tracker = project.trackers.first || Tracker.first
project.trackers << tracker unless project.trackers.include?(tracker)

version = project.versions.find_or_create_by!(name: "v1.0") do |v|
  v.status = "open"
  v.due_date = Date.today + 30
end

statuses = IssueStatus.all.index_by(&:name)
priorities = IssuePriority.all.index_by(&:name)

seed_issues = [
  ["Налаштувати CI/CD пайплайн", "Новий", "Високий"],
  ["Виправити помилку авторизації", "В роботі", "Негайний"],
  ["Оновити документацію API", "Новий", "Низький"],
  ["Провести код-рев'ю модуля оплат", "Виконано", "Звичайний"],
  ["Мігрувати базу даних на новий сервер", "В роботі", "Високий"],
  ["Додати темну тему в адмін-панель", "Закрито", "Звичайний"],
]

seed_issues.each do |subject, status_name, priority_name|
  next if project.issues.exists?(subject: subject)
  issue = Issue.new(
    project: project,
    tracker: tracker,
    subject: subject,
    description: "Тестові дані для перевірки BSYSTEM-теми.",
    author: admin,
    status: statuses[status_name] || IssueStatus.first,
    priority: priorities[priority_name] || IssuePriority.first,
    fixed_version: version,
  )
  issue.save!(validate: false)
end

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

puts "Seeded: #{project.issues.count} issues, wiki page, version #{version.name}"
