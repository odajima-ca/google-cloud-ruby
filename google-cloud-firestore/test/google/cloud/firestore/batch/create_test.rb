# Copyright 2017 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "helper"

describe Google::Cloud::Firestore::Batch, :create, :mock_firestore do
  let(:batch) { Google::Cloud::Firestore::Batch.from_client firestore }

  let(:document_path) { "users/mike" }
  let(:database_path) { "projects/#{project}/databases/(default)" }
  let(:documents_path) { "#{database_path}/documents" }
  let(:commit_time) { Time.now }
  let :create_writes do
    [Google::Firestore::V1::Write.new(
      update: Google::Firestore::V1::Document.new(
        name: "#{documents_path}/#{document_path}",
        fields: Google::Cloud::Firestore::Convert.hash_to_fields({ name: "Mike" })),
      current_document: Google::Firestore::V1::Precondition.new(
        exists: false)
    )]
  end
  let :commit_resp do
    Google::Firestore::V1::CommitResponse.new(
      commit_time: Google::Cloud::Firestore::Convert.time_to_timestamp(commit_time),
      write_results: [Google::Firestore::V1::WriteResult.new(
        update_time: Google::Cloud::Firestore::Convert.time_to_timestamp(commit_time))]
      )
  end

  it "creates a new document given a string path" do
    firestore_mock.expect :commit, commit_resp, [database_path, create_writes, options: default_options]

    batch.create(document_path, { name: "Mike" })
    resp = batch.commit

    resp.must_be_kind_of Google::Cloud::Firestore::CommitResponse
    resp.commit_time.must_equal commit_time
  end

  it "creates a new document given a DocumentReference" do
    firestore_mock.expect :commit, commit_resp, [database_path, create_writes, options: default_options]

    doc = firestore.doc document_path
    doc.must_be_kind_of Google::Cloud::Firestore::DocumentReference

    batch.create(doc, { name: "Mike" })
    resp = batch.commit

    resp.must_be_kind_of Google::Cloud::Firestore::CommitResponse
    resp.commit_time.must_equal commit_time
  end

  it "raises if not given a Hash" do
    error = expect do
      batch.create document_path, "not a hash"
    end.must_raise ArgumentError
    error.message.must_equal "data is required"
  end
end
